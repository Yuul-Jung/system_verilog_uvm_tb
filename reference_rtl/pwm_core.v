`timescale 1ns/1ps
// P2-04: 보드와 무관한 단일 채널 범용 PWM 코어.
// (추가) period와 duty는 클록 횟수 단위. 0%/100%는 지속 LOW/HIGH.
// (추가) 설정은 주기 마지막 경계에서만 활성값으로 반영.
module pwm_core #(
    parameter [31:0] RESET_PERIOD = 32'd100000
)(
    input  wire        clk,
    input  wire        resetn,
    input  wire        cfg_apply,
    input  wire [31:0] cfg_period,
    input  wire [31:0] cfg_duty,
    input  wire        cfg_enable,
    input  wire        cfg_polarity,
    output wire        pwm_out,
    output reg         pending,
    output reg [31:0] active_period,
    output reg [31:0] active_duty,
    output reg         active_enable,
    output reg         active_polarity
);
    reg [31:0] counter;
    reg [31:0] shadow_period;
    reg [31:0] shadow_duty;
    reg        shadow_enable;
    reg        shadow_polarity;

    wire boundary = (counter >= active_period - 32'd1);
    wire duty_high = (counter < active_duty);

    // (주의) enable=0이면 polarity와 관계없이 LOW로 차단.
    // (설명) 기본 polarity에서 active_duty=0이면 항상 LOW,
    //         active_duty=active_period이면 항상 HIGH.
    assign pwm_out = resetn && active_enable &&
                     (active_polarity ? !duty_high : duty_high);

    always @(posedge clk) begin
        if (!resetn) begin
            counter         <= 32'd0;
            active_period   <= RESET_PERIOD;
            active_duty     <= 32'd0;
            active_enable   <= 1'b0;
            active_polarity <= 1'b0;
            shadow_period   <= RESET_PERIOD;
            shadow_duty     <= 32'd0;
            shadow_enable   <= 1'b0;
            shadow_polarity <= 1'b0;
            pending         <= 1'b0;
        end else begin
            if (boundary) begin
                counter <= 32'd0;
                if (pending) begin
                    active_period   <= shadow_period;
                    active_duty     <= shadow_duty;
                    active_enable   <= shadow_enable;
                    active_polarity <= shadow_polarity;
                    pending         <= 1'b0;
                end
            end else begin
                counter <= counter + 32'd1;
            end
            // (추가) 경계와 APPLY가 겹치면 새 값은 다음 경계에 적용.
            // 여러 APPLY가 겹치면 최종 요청값을 우선하는 단일 Shadow 구조.
            if (cfg_apply) begin
                shadow_period   <= cfg_period;
                shadow_duty     <= cfg_duty;
                shadow_enable   <= cfg_enable;
                shadow_polarity <= cfg_polarity;
                pending         <= 1'b1;
            end
        end
    end
endmodule
