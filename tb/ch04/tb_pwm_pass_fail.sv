`timescale 1ns/1ps
// CH04: 기존 pwm_core의 PASS/FAIL 자동 판정 테스트벤치.
module tb_pwm_pass_fail;
    reg clk = 1'b0;
    reg resetn = 1'b0;
    reg cfg_apply = 1'b0;
    reg [31:0] cfg_period = 32'd8;
    reg [31:0] cfg_duty = 32'd0;
    reg cfg_enable = 1'b1;
    reg cfg_polarity = 1'b0;
    wire pwm_out, pending, active_enable, active_polarity;
    wire [31:0] active_period, active_duty;
    integer checks = 0, errors = 0, step;

    // 원본 RTL의 13개 포트를 동일한 이름으로 연결.
    pwm_core #(.RESET_PERIOD(32'd8)) dut (
        .clk(clk), .resetn(resetn),
        .cfg_apply(cfg_apply), .cfg_period(cfg_period),
        .cfg_duty(cfg_duty), .cfg_enable(cfg_enable),
        .cfg_polarity(cfg_polarity), .pwm_out(pwm_out),
        .pending(pending), .active_period(active_period),
        .active_duty(active_duty), .active_enable(active_enable),
        .active_polarity(active_polarity)
    );
    always #5 clk = ~clk; // 10ns 주기

    // (추가) X/Z까지 검사하는 4상태 비교.
    task automatic check_bit(input reg actual, input reg expected);
        begin
            checks = checks + 1;
            if (actual !== expected) begin
                errors = errors + 1;
                $error("MISMATCH t=%0t actual=%b expected=%b",
                    $time, actual, expected);
            end
        end
    endtask

    // (추가) 설정 요청 뒤 Shadow 수락과 Active 반영을 모두 기다림.
    task automatic apply_duty(input [31:0] requested);
        begin
            @(negedge clk);
            cfg_duty = requested;
            cfg_apply = 1'b1;
            @(negedge clk);
            cfg_apply = 1'b0;
            wait (pending === 1'b1);
            wait (pending === 1'b0);
            #1; // NBA 반영 후 안정된 값 검사
            checks = checks + 1;
            if (active_duty !== requested) begin
                errors = errors + 1;
                $error("ACTIVE_DUTY expected=%0d actual=%0d",
                    requested, active_duty);
            end
            $display("APPLIED duty=%0d t=%0t", requested, $time);
        end
    endtask

    // (추가) 내부 counter를 참조하지 않는 독립 기준값.
    task automatic check_period(input integer duty_ticks);
        integer sample, high_count;
        begin
            high_count = 0;
            for (sample = 0; sample < 8; sample = sample + 1) begin
                @(negedge clk);
                if (pwm_out === 1'b1)
                    high_count = high_count + 1;
                if ((pwm_out !== 1'b0) && (pwm_out !== 1'b1)) begin
                    errors = errors + 1;
                    $error("UNKNOWN_PWM sample=%0d pwm=%b",
                        sample, pwm_out);
                end
            end
            checks = checks + 1;
            if (high_count !== duty_ticks) begin
                errors = errors + 1;
                $error("HIGH_COUNT duty=%0d expected=%0d actual=%0d",
                    duty_ticks, duty_ticks, high_count);
            end
            $display("CHECK duty=%0d high=%0d/8 expected=%0d/8",
                duty_ticks, high_count, duty_ticks);
        end
    endtask

    initial begin
        $dumpfile("ch04_pwm_pass_fail.vcd");
        $dumpvars(0, tb_pwm_pass_fail);
    end
    initial begin
        #2000;
        $fatal(1, "TIMEOUT: pending 적용 완료 대기 초과");
    end
    initial begin
        $display("=== CH04 PWM SELF-CHECK START ===");
        repeat (2) @(negedge clk);
        check_bit(pwm_out, 1'b0);
        resetn = 1'b1;
        for (step = 0; step <= 8; step = step + 2) begin
            apply_duty(step);
            check_period(step);
        end
        if (errors == 0) begin
            $display("PASS checks=%0d errors=0", checks);
            $finish;
        end else begin
            $fatal(1, "FAIL checks=%0d errors=%0d", checks, errors);
        end
    end
endmodule
