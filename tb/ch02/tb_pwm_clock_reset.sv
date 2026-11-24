`timescale 1ns/1ps
// 제02장: 기존 pwm_core의 클록·리셋·주기 경계를 관찰한다.
// DUT 원본은 변경하지 않는다. 자동 PASS/FAIL 판정은 제04장에서 다룬다.
module tb_pwm_clock_reset;
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

    // (추가) 실제 DUT의 모든 포트를 원래 이름으로 연결한다.
    // RESET_PERIOD만 교육용으로 8클록으로 축소한다.
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

    // 5ns마다 반전하므로 클록의 전체 주기는 10ns이다.
    initial clk = 1'b0;
    always #5 clk = ~clk;

`ifdef VCD
    // (변경) Icarus 실행에서만 VCD 시스템 태스크를 활성화한다.
    initial begin
        $dumpfile("ch02_pwm_clock_reset.vcd");
        $dumpvars(0, tb_pwm_clock_reset);
    end
`endif

    // (변경) %0d로 $time의 현재 모듈 시간 단위(ns)를 그대로 표시한다.
    // 상승 에지 이후 1ns를 기다려 비차단 대입 결과를 읽는다.
    // #1은 하드웨어 지연이 아니라 테스트벤치 관찰용 시간 이동이다.
    always @(posedge clk) begin
        #1;
        $display("POS t=%0d ns rst=%b apply=%b pending=%b period=%0d duty=%0d en=%b pwm=%b",
            $time, resetn, cfg_apply, pending,
            active_period, active_duty, active_enable, pwm_out);
    end

    initial begin
        // 0~20ns: 활성 LOW 리셋을 유지한다.
        resetn       = 1'b0;
        cfg_apply    = 1'b0;
        cfg_period   = 32'd8;
        cfg_duty     = 32'd3;
        cfg_enable   = 1'b1;
        cfg_polarity = 1'b0;
        $display("=== CH02 PWM CLOCK / RESET START ===");

        // t=20ns 하강 에지에 리셋 해제.
        @(negedge clk);
        @(negedge clk);
        resetn = 1'b1;

        // t=30~40ns 설정 요청, t=35ns Shadow 저장.
        @(negedge clk);
        cfg_apply = 1'b1;
        @(negedge clk);
        cfg_apply = 1'b0;

        // t=190ns: PWM이 HIGH인 구간에서 리셋 재인가.
        repeat (15) @(negedge clk);
        resetn = 1'b0;
        #1;
        // 리셋 입력만 LOW로 바뀌어도 조합 출력은 즉시 LOW가 된다.
        $display("EVENT t=%0d ns resetn=%b active_duty=%0d pwm=%b",
            $time, resetn, active_duty, pwm_out);

        // t=195ns 순차 레지스터 리셋, t=200ns 리셋 해제.
        @(negedge clk);
        resetn = 1'b1;

        repeat (4) @(negedge clk);
        $display("=== CH02 END: OBSERVATION ONLY ===");
        $finish;
    end
endmodule
