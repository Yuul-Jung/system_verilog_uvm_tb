`timescale 1ns/1ps
// 제03장: task, function, repeat, for, wait로 PWM 입력 자극을 재사용한다.
// DUT는 기존 pwm_core 원본을 참조하며, 이 TB는 관찰용이다.
// 자동 PASS/FAIL 판정은 제04장에서 다룬다.
module tb_pwm_reusable_stimulus;
    reg         clk;
    reg         resetn;
    reg         cfg_apply;
    reg  [31:0] cfg_period;
    reg  [31:0] cfg_duty;
    reg         cfg_enable;
    reg         cfg_polarity;

    wire        pwm_out;
    wire        pending;
    wire [31:0] active_period;
    wire [31:0] active_duty;
    wire        active_enable;
    wire        active_polarity;

    // 원본 RTL의 포트 13개를 이름 그대로 연결한다.
    // 인스턴스 초기 주기만 8클록으로 축소해 관찰 시간을 절약한다.
    pwm_core #(.RESET_PERIOD(32'd8)) dut (
        .clk             (clk),
        .resetn          (resetn),
        .cfg_apply       (cfg_apply),
        .cfg_period      (cfg_period),
        .cfg_duty        (cfg_duty),
        .cfg_enable      (cfg_enable),
        .cfg_polarity    (cfg_polarity),
        .pwm_out         (pwm_out),
        .pending         (pending),
        .active_period   (active_period),
        .active_duty     (active_duty),
        .active_enable   (active_enable),
        .active_polarity (active_polarity)
    );

    // (추가) 클록 주기: 5ns + 5ns → 10ns.
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // (추가) function은 시뮬레이션 시간을 소비하지 않고 값을 반환한다.
    // 실습 범위는 period=8이므로 나눗셈 분모는 항상 0이 아니다.
    function automatic integer duty_percent(
        input [31:0] high_ticks,
        input [31:0] period_ticks
    );
        begin
            duty_percent = (high_ticks * 100) / period_ticks;
        end
    endfunction

    // (추가) 설정 요청을 매번 중복 작성하지 않고 task 한 곳에 모은다.
    // cfg_apply는 하강 에지에서 한 클록 동안 유지한다.
    task automatic request_pwm(input [31:0] duty_ticks);
        begin
            @(negedge clk);
            cfg_duty  = duty_ticks;
            cfg_apply = 1'b1;
            $display("REQUEST t=%0d ns duty=%0d", $time, duty_ticks);

            @(negedge clk);
            cfg_apply = 1'b0;

            // 먼저 Shadow 저장 완료를 확인한 뒤 적용 완료를 기다린다.
            // pending=0만 즉시 검사하면 이전 상태를 오인할 수 있다.
            wait (pending === 1'b1);
            wait (pending === 1'b0);
            #1;
            $display("APPLIED t=%0d ns duty=%0d percent=%0d",
                $time, active_duty,
                duty_percent(active_duty, active_period));
        end
    endtask

    // (추가) 한 PWM 주기의 8개 하강 에지에서 출력을 샘플링한다.
    // 표본 개수를 표시할 뿐, 아직 기대값과 자동 비교하지 않는다.
    task automatic observe_one_period;
        integer cycle_index;
        integer high_samples;
        begin
            high_samples = 0;

            for (cycle_index = 0; cycle_index < 8;
                 cycle_index = cycle_index + 1) begin
                @(negedge clk);
                if (pwm_out === 1'b1)
                    high_samples = high_samples + 1;

                $display("SAMPLE duty=%0d cycle=%0d pwm=%b",
                    active_duty, cycle_index, pwm_out);
            end

            $display("OBSERVED duty=%0d HIGH=%0d/8",
                active_duty, high_samples);
        end
    endtask

`ifdef VCD
    initial begin
        $dumpfile("ch03_pwm_reusable_stimulus.vcd");
        $dumpvars(0, tb_pwm_reusable_stimulus);
    end
`endif

    // (추가) 시뮬레이션 무한 대기를 방지하기 위한 안전 종료.
    initial begin
        #2000;
        // (변경) 제한 시간 초과를 실행 오류로 전달한다.
        $fatal(1, "TIMEOUT: PWM 설정 완료 신호를 확인하세요.");
    end

    integer duty_step;

    initial begin
        resetn       = 1'b0;
        cfg_apply    = 1'b0;
        cfg_period   = 32'd8;
        cfg_duty     = 32'd0;
        cfg_enable   = 1'b1;
        cfg_polarity = 1'b0;

        $display("=== CH03 REUSABLE STIMULUS START ===");

        // (추가) 리셋을 두 번의 하강 에지 동안 유지한다.
        repeat (2) @(negedge clk);
        resetn = 1'b1;

        // (추가) 0, 2, 4, 6, 8클록의 Duty를 순서대로 시험한다.
        // cfg_period=8이므로 0%, 25%, 50%, 75%, 100%가 된다.
        for (duty_step = 0; duty_step <= 8;
             duty_step = duty_step + 2) begin
            request_pwm(duty_step);
            observe_one_period();
        end

        $display("=== CH03 END: OBSERVATION ONLY ===");
        $finish;
    end
endmodule
