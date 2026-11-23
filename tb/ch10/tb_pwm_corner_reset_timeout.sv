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

    pwm_core #(.RESET_PERIOD(32'd8)) dut (
        .clk(clk), .resetn(resetn), .cfg_apply(cfg_apply),
        .cfg_period(cfg_period), .cfg_duty(cfg_duty),
        .cfg_enable(cfg_enable), .cfg_polarity(cfg_polarity),
        .pwm_out(pwm_out), .pending(pending),
        .active_period(active_period), .active_duty(active_duty),
        .active_enable(active_enable), .active_polarity(active_polarity)
    );
    always #5 clk = ~clk;

    // 실패 시 무한 대기하지 않도록 전체 시뮬레이션에 상한을 둔다.
    initial begin
        #5000;
        $fatal(1, "FAIL GLOBAL_TIMEOUT");
    end

    // 모든 검사는 NBA 갱신 뒤 수행한다.
    task check_outputs(input [31:0] expected_duty,
                       input expected_pwm, input expected_pending);
        begin
            if (active_period !== 32'd8 ||
                active_duty !== expected_duty ||
                active_enable !== 1'b1 ||
                active_polarity !== 1'b0 ||
                pending !== expected_pending ||
                pwm_out !== expected_pwm)
                $fatal(1, "FAIL t=%0t duty=%0d pwm=%b pending=%b",
                       $time, active_duty, pwm_out, pending);
            checks = checks + 1;
        end
    endtask

    // 하강 에지에서 요청을 변경하여 상승 에지 경쟁을 피한다.
    task request_duty(input [31:0] duty);
        begin
            @(negedge clk);
            cfg_period = 32'd8;
            cfg_duty = duty;
            cfg_enable = 1'b1;
            cfg_polarity = 1'b0;
            cfg_apply = 1'b1;
            @(negedge clk);
            cfg_apply = 1'b0;
            requests = requests + 1;
            if (pending !== 1'b1)
                $fatal(1, "FAIL request not pending");
        end
    endtask

    // 주기 8클록, 듀티 0 또는 8에서 모든 샘플이 일정해야 한다.
    task check_constant_window(input [31:0] duty,
                               input expected_level);
        integer i;
        begin
            request_duty(duty);
            // pending은 다음 주기 경계에서 해제된다.
            for (i = 0; i < 10 && pending !== 1'b0; i = i + 1) begin
                @(posedge clk); #1;
            end
            if (pending !== 1'b0 || active_duty !== duty)
                $fatal(1, "FAIL APPLY_TIMEOUT duty=%0d", duty);
            for (i = 0; i < 16; i = i + 1) begin
                @(posedge clk); #1;
                check_outputs(duty, expected_level, 1'b0);
            end
        end
    endtask

    initial begin
        // 동기 리셋: 첫 상승 에지 이후 초기 레지스터를 검사한다.
        @(posedge clk); #1;
        if (active_period !== 32'd8 || active_duty !== 0 ||
            active_enable !== 0 || pending !== 0 || pwm_out !== 0)
            $fatal(1, "FAIL initial reset");
        @(negedge clk);
        resetn = 1'b1;

        check_constant_window(32'd0, 1'b0); // 0%: 항상 LOW
        check_constant_window(32'd8, 1'b1); // 100%: 항상 HIGH

        // 동작 중 리셋을 하강 에지 사이에 가한다.
        #2 resetn = 1'b0;
        #1;
        if (pwm_out !== 1'b0)
            $fatal(1, "FAIL async output gate");
        @(posedge clk); #1;
        if (active_period !== 32'd8 || active_duty !== 0 ||
            active_enable !== 0 || pending !== 0 || pwm_out !== 0)
            $fatal(1, "FAIL synchronous register reset");
        @(negedge clk);
        resetn = 1'b1;

        check_constant_window(32'd8, 1'b1); // 리셋 뒤 재설정
        $display("PASS CH10 requests=%0d checks=%0d", requests, checks);
        $finish;
    end
endmodule
