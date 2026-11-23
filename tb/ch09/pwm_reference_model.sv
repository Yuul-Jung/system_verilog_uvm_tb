`timescale 1ns/1ps
// (추가) 제09장: 공개 PWM 계약으로 예상값을 계산하는 독립 참조 모델.
// DUT 내부 신호 counter, boundary, shadow_*는 참조하지 않는다.
module pwm_reference_model #(
    parameter [31:0] INITIAL_PERIOD = 32'd8
)(
    input wire clk, resetn, cfg_apply,
    input wire [31:0] cfg_period, cfg_duty,
    input wire cfg_enable, cfg_polarity,
    output wire ref_pwm,
    output reg ref_pending,
    output reg [31:0] ref_period, ref_duty,
    output reg ref_enable, ref_polarity
);
    reg [31:0] phase, queued_period, queued_duty;
    reg queued_enable, queued_polarity;

    // 주기/듀티 기준으로 DUT와 별개 예상 파형을 구한다.
    // 이번 장의 입력 주기는 항상 8이므로 0 주기는 다루지 않는다.
    wire period_end = (phase + 32'd1 >= ref_period);
    wire high_window = (phase < ref_duty);
    assign ref_pwm = resetn && ref_enable &&
                     (ref_polarity ? !high_window : high_window);

    always @(posedge clk) begin
        if (!resetn) begin
            phase           <= 32'd0;
            ref_period      <= INITIAL_PERIOD;
            ref_duty        <= 32'd0;
            ref_enable      <= 1'b0;
            ref_polarity    <= 1'b0;
            queued_period   <= INITIAL_PERIOD;
            queued_duty     <= 32'd0;
            queued_enable   <= 1'b0;
            queued_polarity <= 1'b0;
            ref_pending     <= 1'b0;
        end else begin
            // 현재 주기를 완료한 뒤 대기 중인 설정을 반영한다.
            if (period_end) begin
                phase <= 32'd0;
                if (ref_pending) begin
                    ref_period   <= queued_period;
                    ref_duty     <= queued_duty;
                    ref_enable   <= queued_enable;
                    ref_polarity <= queued_polarity;
                    ref_pending  <= 1'b0;
                end
            end else begin
                phase <= phase + 32'd1;
            end

            // 경계와 cfg_apply가 겹치면 새 값은 다음 경계에서 적용.
            if (cfg_apply) begin
                queued_period   <= cfg_period;
                queued_duty     <= cfg_duty;
                queued_enable   <= cfg_enable;
                queued_polarity <= cfg_polarity;
                ref_pending     <= 1'b1;
            end
        end
    end
endmodule
