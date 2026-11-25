`timescale 1ns/1ps
// (추가) 제09장: DUT와 참조 모델의 공개 출력 6개를 자동 비교한다.
module tb_pwm_scoreboard;
    reg clk = 1'b0, resetn = 1'b0, cfg_apply = 1'b0;
    reg [31:0] cfg_period = 32'd8, cfg_duty = 32'd0;
    reg cfg_enable = 1'b1, cfg_polarity = 1'b0;

    wire pwm_out, pending, active_enable, active_polarity;
    wire [31:0] active_period, active_duty;
    wire ref_pwm, ref_pending, ref_enable, ref_polarity;
    wire [31:0] ref_period, ref_duty;
    integer score_cycles = 0, scenarios = 0;

    // (추가) 원본 DUT 13포트를 변경 없이 연결한다.
    pwm_core #(.RESET_PERIOD(32'd8)) dut (
        .clk(clk), .resetn(resetn), .cfg_apply(cfg_apply),
        .cfg_period(cfg_period), .cfg_duty(cfg_duty),
        .cfg_enable(cfg_enable), .cfg_polarity(cfg_polarity),
        .pwm_out(pwm_out), .pending(pending),
        .active_period(active_period), .active_duty(active_duty),
        .active_enable(active_enable), .active_polarity(active_polarity)
    );

    // (추가) 같은 입력을 독립된 Golden(정답) 모델에도 공급한다.
    pwm_reference_model #(.INITIAL_PERIOD(32'd8)) golden (
        .clk(clk), .resetn(resetn), .cfg_apply(cfg_apply),
        .cfg_period(cfg_period), .cfg_duty(cfg_duty),
        .cfg_enable(cfg_enable), .cfg_polarity(cfg_polarity),
        .ref_pwm(ref_pwm), .ref_pending(ref_pending),
        .ref_period(ref_period), .ref_duty(ref_duty),
        .ref_enable(ref_enable), .ref_polarity(ref_polarity)
    );

    // 입력 자극은 하강 에지에서, 비교는 상승 에지 이후에 수행한다.
    always #5 clk = ~clk;

    // (추가) scoreboard: 4상태 비교 !==로 X/Z까지 놓치지 않는다.
    // #1은 비차단 대입이 완료된 뒤 읽는 테스트벤치 관찰 지연이다.
    always @(posedge clk) begin
        #1;
        score_cycles = score_cycles + 1;
        // (추가) 양쪽이 같은 X/Z여도 정상으로 판정하지 않는다.
        // Reduction XOR는 묶음에 X/Z가 있으면 X를 반환한다.
        if ((^{pwm_out, pending, active_period, active_duty,
               active_enable, active_polarity}) === 1'bx ||
            (^{ref_pwm, ref_pending, ref_period, ref_duty,
               ref_enable, ref_polarity}) === 1'bx)
            $fatal(1, "UNKNOWN_OUTPUT t=%0d", $time);
        if ((pwm_out         !== ref_pwm)      ||
            (pending         !== ref_pending)  ||
            (active_period   !== ref_period)   ||
            (active_duty     !== ref_duty)     ||
            (active_enable   !== ref_enable)   ||
            (active_polarity !== ref_polarity)) begin
            $display("EXPECTED t=%0d pwm=%b pend=%b period=%0d duty=%0d en=%b pol=%b",
                $time, ref_pwm, ref_pending, ref_period,
                ref_duty, ref_enable, ref_polarity);
            $fatal(1,
                "FAIL t=%0d pwm=%b pend=%b period=%0d duty=%0d en=%b pol=%b",
                $time, pwm_out, pending, active_period,
                active_duty, active_enable, active_polarity);
        end
    end

    // (추가) 설정을 한 클록만 HIGH로 전달하는 재사용 태스크.
    task automatic request_config(
        input integer case_id,
        input [31:0] duty_ticks,
        input reg enabled, inverted
    );
        begin
            @(negedge clk);
            cfg_period   = 32'd8;
            cfg_duty     = duty_ticks;
            cfg_enable   = enabled;
            cfg_polarity = inverted;
            cfg_apply    = 1'b1;
            scenarios = scenarios + 1;
            $display("REQUEST case=%0d t=%0d duty=%0d en=%b pol=%b",
                case_id, $time, duty_ticks, enabled, inverted);
            @(negedge clk);
            cfg_apply = 1'b0;
        end
    endtask

`ifdef VCD
    // (변경) VCD는 Icarus 실행에서만 활성화한다.
    initial begin
        $dumpfile("ch09_pwm_scoreboard.vcd");
        $dumpvars(0, tb_pwm_scoreboard);
    end
`endif
    initial begin
        #1200;
        $fatal(1, "CH09 TIMEOUT: 검증이 정상 종료되지 않음");
    end

    initial begin
        $display("=== CH09 PWM MODEL / SCOREBOARD START ===");

        repeat (2) @(negedge clk); // t=20ns 초기 리셋 해제
        resetn = 1'b1;

        request_config(1, 32'd2, 1'b1, 1'b0); // t=30ns: 25%
        repeat (9) @(negedge clk);

        request_config(2, 32'd6, 1'b1, 1'b0); // t=140ns: 75%
        repeat (9) @(negedge clk);

        // t=250ns 요청이 t=255ns 주기 경계와 겹친다.
        // 새 극성은 다음 주기 경계(t=335ns)에 반영되어야 한다.
        request_config(3, 32'd6, 1'b1, 1'b1);
        repeat (9) @(negedge clk);

        request_config(4, 32'd6, 1'b0, 1'b1); // 출력 차단
        repeat (9) @(negedge clk);

        request_config(5, 32'd8, 1'b1, 1'b0); // 100% HIGH
        repeat (9) @(negedge clk);

        // t=580ns: PWM HIGH 상태에서 LOW 리셋 인가.
        @(negedge clk);
        // (추가) 이미 LOW라면 출력 차단 검사가 무의미하므로 선행 조건 확인.
        if ((pwm_out !== 1'b1) || (ref_pwm !== 1'b1))
            $fatal(1, "FAIL RESET_PRECONDITION: expected HIGH");
        resetn = 1'b0;
        #1;
        if ((pwm_out !== 1'b0) || (ref_pwm !== 1'b0))
            $fatal(1, "FAIL RESET_GATE: 출력 즉시 LOW 실패");
        $display("RESET_GATE PASS t=%0d", $time);

        repeat (2) @(negedge clk); // t=600ns 리셋 해제
        resetn = 1'b1;
        request_config(6, 32'd0, 1'b1, 1'b0); // 0% 듀티
        repeat (10) @(negedge clk);

        // (추가) 현재 고정 시나리오의 전체 비교·요청 횟수 확인.
        if (score_cycles != 72 || scenarios != 6)
            $fatal(1, "FAIL COUNT cycles=%0d scenarios=%0d",
                score_cycles, scenarios);
        $display("PASS CH09 score_cycles=%0d scenarios=%0d",
            score_cycles, scenarios);
        $finish;
    end
endmodule
