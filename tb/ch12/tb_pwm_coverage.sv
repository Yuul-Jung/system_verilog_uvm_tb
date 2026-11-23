`timescale 1ns/1ps
// 제12장: 원본 pwm_core의 설정 조합을 기능 커버리지로 측정한다.
// 기능 커버리지는 '입력 조합을 실제로 적용했는가'를 기록한다.
// PWM의 정확한 파형은 8클록 HIGH 개수 검사로 별도 판정한다.
module tb_pwm_coverage;
    logic clk = 0;
    logic resetn = 0;
    logic cfg_apply = 0;
    logic [31:0] cfg_period = 32'd8;
    logic [31:0] cfg_duty = 0;
    logic cfg_enable = 0;
    logic cfg_polarity = 0;
    wire pwm_out, pending, active_enable, active_polarity;
    wire [31:0] active_period, active_duty;
    int checks = 0;

    pwm_core #(.RESET_PERIOD(32'd8)) dut (
        .clk(clk), .resetn(resetn), .cfg_apply(cfg_apply),
        .cfg_period(cfg_period), .cfg_duty(cfg_duty),
        .cfg_enable(cfg_enable), .cfg_polarity(cfg_polarity),
        .pwm_out(pwm_out), .pending(pending),
        .active_period(active_period), .active_duty(active_duty),
        .active_enable(active_enable), .active_polarity(active_polarity)
    );
    always #5 clk = ~clk;

    // 명시적 sample()을 호출하므로 리셋/설정 대기 구간은 기록하지 않는다.
    covergroup pwm_cfg_cg with function sample(
        int unsigned duty, bit en, bit pol
    );
        option.per_instance = 1;
        cp_duty: coverpoint duty {
            bins zero = {0};
            bins middle = {[1:7]};
            bins full = {8};
            illegal_bins outside = default;
        }
        cp_enable: coverpoint en {
            bins disabled = {0};
            bins enabled = {1};
        }
        cp_polarity: coverpoint pol {
            bins normal = {0};
            bins inverted = {1};
        }
        cx_settings: cross cp_duty, cp_enable, cp_polarity;
    endgroup
    pwm_cfg_cg cov = new();

    task automatic run_case(
        input logic [31:0] duty,
        input logic en, input logic pol
    );
        int waited;
        int highs;
        int expected_highs;
        // 음의 에지에서 입력을 바꿔 양의 에지 샘플과 충돌하지 않는다.
        @(negedge clk);
        cfg_duty = duty;
        cfg_enable = en;
        cfg_polarity = pol;
        cfg_apply = 1;
        @(negedge clk);
        cfg_apply = 0;
        if (pending !== 1'b1)
            $fatal(1, "FAIL pending did not assert");

        // 실제 DUT는 shadow 값을 주기 경계에서 활성화한다.
        waited = 0;
        while (pending !== 1'b0 && waited < 24) begin
            @(negedge clk);
            waited++;
        end
        if (pending !== 1'b0 || active_period !== 32'd8 ||
            active_duty !== duty || active_enable !== en ||
            active_polarity !== pol)
            $fatal(1, "FAIL apply duty=%0d en=%b pol=%b", duty, en, pol);

        // 8개의 연속된 PWM 클록을 관찰하면 정확히 한 주기이다.
        // enable=0이면 polarity와 무관하게 LOW가 유지된다.
        highs = 0;
        for (int i = 0; i < 8; i++) begin
            @(negedge clk);
            if (pwm_out === 1'bx || pwm_out === 1'bz)
                $fatal(1, "FAIL unknown pwm_out");
            if (pwm_out) highs++;
        end
        expected_highs = en ? (pol ? 8 - int'(duty) : int'(duty)) : 0;
        if (highs != expected_highs)
            $fatal(1, "FAIL waveform duty=%0d en=%b pol=%b high=%0d expected=%0d",
                   duty, en, pol, highs, expected_highs);

        // 출력 검사가 끝난 실제 적용 조합만 커버리지에 포함한다.
        cov.sample(duty, en, pol);
        checks++;
        $display("CHECK duty=%0d en=%b pol=%b highs=%0d",
                 duty, en, pol, highs);
    endtask

    initial begin
        #10000;
        $fatal(1, "FAIL GLOBAL_TIMEOUT");
    end

    initial begin
        $dumpfile("ch12_pwm_coverage.vcd");
        $dumpvars(0, tb_pwm_coverage);
        repeat (3) @(negedge clk);
        resetn = 1;
        // 3 듀티 구간 × 2 enable × 2 polarity = 12개 cross bin.
        for (int d = 0; d < 3; d++) begin
            for (int e = 0; e < 2; e++) begin
                for (int p = 0; p < 2; p++) begin
                    case (d)
                        0: run_case(32'd0, bit'(e), bit'(p));
                        1: run_case(32'd4, bit'(e), bit'(p));
                        2: run_case(32'd8, bit'(e), bit'(p));
                    endcase
                end
            end
        end
        if (checks != 12)
            $fatal(1, "FAIL missing test cases");
        if (cov.get_coverage() < 99.99)
            $fatal(1, "FAIL coverage=%0.2f", cov.get_coverage());
        $display("PASS CH12 cases=%0d coverage=%0.2f%%",
                 checks, cov.get_coverage());
        $finish;
    end
endmodule
