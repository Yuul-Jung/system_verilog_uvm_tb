`timescale 1ns/1ps
// 제10장: PWM 경계값, 실행 중 리셋, 타임아웃을 자동 판정한다.
// 원본 pwm_core는 수정하지 않고 공개 포트만 사용한다.
module tb_pwm_corner_reset_timeout;
    reg clk = 1'b0;
    reg resetn = 1'b0;
    reg cfg_apply = 1'b0;
    reg [31:0] cfg_period = 32'd8, cfg_duty = 32'd0;
    reg cfg_enable = 1'b1, cfg_polarity = 1'b0;
    wire pwm_out, pending, active_enable, active_polarity;
    wire [31:0] active_period, active_duty;
    integer checks = 0;
    integer requests = 0;

    // (추가) 관찰값 오류 및 설정 요청 누락을 DUT 외부에서 주입한다.
    // +INJECT_FAULT: 측정 경로만 반전 → 스코어보드 검출 시험.
    // +INJECT_TIMEOUT: 듀티 8 요청을 누락 → 적용 기한 검출 시험.
    reg inject_fault = 1'b0;
    reg inject_timeout = 1'b0;
    reg corrupt_observation = 1'b0;
    wire measured_pwm = pwm_out ^ corrupt_observation;

    pwm_core #(.RESET_PERIOD(32'd8)) dut (
        .clk(clk), .resetn(resetn), .cfg_apply(cfg_apply),
        .cfg_period(cfg_period), .cfg_duty(cfg_duty),
        .cfg_enable(cfg_enable), .cfg_polarity(cfg_polarity),
        .pwm_out(pwm_out), .pending(pending),
        .active_period(active_period), .active_duty(active_duty),
        .active_enable(active_enable), .active_polarity(active_polarity)
    );
    always #5 clk = ~clk;

`ifdef VCD
    // (변경) Icarus 실행에서만 VCD 기록을 활성화한다.
    initial begin
        $dumpfile("ch10_pwm_corner_reset_timeout.vcd");
        $dumpvars(0, tb_pwm_corner_reset_timeout);
    end
`endif

    // 실패 시 무한 대기하지 않도록 전체 시뮬레이션에 상한을 둔다.
    initial begin
        #5000;
        $fatal(1, "FAIL GLOBAL_TIMEOUT");
    end

    // (변경) 상태 검사와 PWM 측정값 검사를 구별한다.
    // 주입 시험에서 DUT 원본 pwm_out은 변경하지 않는다.
    task automatic check_outputs(
        input [31:0] expected_duty,
        input expected_pwm,
        input expected_pending
    );
        begin
            if (active_period !== 32'd8 ||
                active_duty !== expected_duty ||
                active_enable !== 1'b1 ||
                active_polarity !== 1'b0 ||
                pending !== expected_pending) begin
                $fatal(1, "FAIL STATE duty=%0d pending=%b", active_duty, pending);
            end

            if (measured_pwm !== expected_pwm) begin
                if (corrupt_observation && (pwm_out === expected_pwm))
                    $fatal(1, "DETECTED_INJECTED_FAULT dut=%b measured=%b",
                        pwm_out, measured_pwm);
                $fatal(1, "FAIL PWM actual=%b expected=%b",
                    measured_pwm, expected_pwm);
            end
            checks = checks + 1;
        end
    endtask

    // (변경) +INJECT_TIMEOUT이면 DUT가 아니라 외부 cfg_apply를 누락한다.
    task automatic request_duty(input [31:0] duty);
        reg withhold_apply;
        begin
            @(negedge clk);
            withhold_apply = inject_timeout && (duty == 32'd8);
            cfg_period = 32'd8;
            cfg_duty = duty;
            cfg_enable = 1'b1;
            cfg_polarity = 1'b0;
            cfg_apply = !withhold_apply;
            @(negedge clk);
            cfg_apply = 1'b0;
            requests = requests + 1;
            if (!withhold_apply && pending !== 1'b1)
                $fatal(1, "FAIL request not pending");
            if (withhold_apply)
                $display("INJECT: cfg_apply intentionally withheld");
        end
    endtask

    // (변경) pending과 active_duty를 모두 확인한 뒤 전체 두 주기를 검사한다.
    task automatic check_constant_window(
        input [31:0] duty,
        input expected_level
    );
        integer i;
        begin
            request_duty(duty);

            // 최대 10클록 동안 새 설정의 실제 적용을 기다린다.
            for (i = 0; i < 10 &&
                 ((pending !== 1'b0) || (active_duty !== duty));
                 i = i + 1) begin
                @(posedge clk);
                #1;
                // (추가) 요청 누락 시험에서 기존 정상 0% 상태를 확인한다.
                // 다른 상태 오류를 의도된 타임아웃 성공으로 오인하지 않는다.
                if (inject_timeout && duty == 32'd8 &&
                    (pending !== 1'b0 || active_period !== 32'd8 ||
                     active_duty !== 32'd0 || active_enable !== 1'b1 ||
                     active_polarity !== 1'b0 || pwm_out !== 1'b0))
                    $fatal(1, "FAIL TIMEOUT_BASELINE");
            end

            if (pending !== 1'b0 || active_duty !== duty) begin
                if (inject_timeout && duty == 32'd8)
                    $fatal(1, "DETECTED_APPLY_TIMEOUT duty=8 deadline=10clks");
                $fatal(1, "FAIL APPLY_TIMEOUT duty=%0d", duty);
            end

            // (추가) DUT 출력은 손대지 않고 관찰 회로에서만 비트 반전.
            corrupt_observation = inject_fault && (duty == 32'd8);
            for (i = 0; i < 16; i = i + 1) begin
                @(posedge clk);
                #1;
                check_outputs(duty, expected_level, 1'b0);
            end
            corrupt_observation = 1'b0;
        end
    endtask

    initial begin
        inject_fault = $test$plusargs("INJECT_FAULT");
        inject_timeout = $test$plusargs("INJECT_TIMEOUT");
        if (inject_fault && inject_timeout)
            $fatal(1, "FAIL: 동시에 두 오류 모드를 선택하지 마세요");

        // 동기 리셋: 첫 상승 에지 이후 초기 레지스터를 검사한다.
        @(posedge clk); #1;
        if (active_period !== 32'd8 || active_duty !== 32'd0 ||
            active_enable !== 1'b0 || active_polarity !== 1'b0 ||
            pending !== 1'b0 || pwm_out !== 1'b0)
            $fatal(1, "FAIL initial reset");
        @(negedge clk);
        resetn = 1'b1;

        check_constant_window(32'd0, 1'b0); // 0%: 항상 LOW
        check_constant_window(32'd8, 1'b1); // 100%: 항상 HIGH

        // (추가) 출력이 HIGH인 상태에서 리셋 차단을 검사한다.
        if (pwm_out !== 1'b1)
            $fatal(1, "FAIL RESET_PRECONDITION");
        // 직전 상승 에지의 관찰 후 2ns, 다음 상승 에지 전에 인가.
        #2 resetn = 1'b0;
        #1;
        if (pwm_out !== 1'b0)
            $fatal(1, "FAIL async output gate");
        @(posedge clk); #1;
        if (active_period !== 32'd8 || active_duty !== 32'd0 ||
            active_enable !== 1'b0 || active_polarity !== 1'b0 ||
            pending !== 1'b0 || pwm_out !== 1'b0)
            $fatal(1, "FAIL synchronous register reset");
        @(negedge clk);
        resetn = 1'b1;

        check_constant_window(32'd8, 1'b1); // 리셋 뒤 재설정
        // (추가) 세 요청과 세 묶음의 16회 검사 완료 확인.
        if (requests != 3 || checks != 48)
            $fatal(1, "FAIL COUNT requests=%0d checks=%0d", requests, checks);
        $display("PASS CH10 requests=%0d checks=%0d", requests, checks);
        $finish;
    end
endmodule
