`timescale 1ns/1ps
`default_nettype none

// DSP48E1의 25x18 signed 입력 범위에 맞춘 독립 곱셈 추론 후보.
// primitive를 직접 생성하지 않으며 실제 DSP 배치는 합성 후 확인한다.
module dsp_multiplier #(
    parameter integer A_WIDTH = 16,
    parameter integer B_WIDTH = 16
) (
    input wire clk,
    input wire resetn,
    input wire clear_i,
    input wire valid_i,
    input wire signed [A_WIDTH-1:0] a_i,
    input wire signed [B_WIDTH-1:0] b_i,
    output reg signed [A_WIDTH+B_WIDTH-1:0] product_o,
    output reg valid_o
);
    wire signed [24:0] a_dsp_w;
    wire signed [17:0] b_dsp_w;
    (* use_dsp = "yes" *) wire signed [42:0] product_full_w;

    // 작은 정수의 부호를 보존하여 DSP 곱셈 입력 폭까지 확장한다.
    assign a_dsp_w = {{(25-A_WIDTH){a_i[A_WIDTH-1]}}, a_i};
    assign b_dsp_w = {{(18-B_WIDTH){b_i[B_WIDTH-1]}}, b_i};
    assign product_full_w = $signed(a_dsp_w) * $signed(b_dsp_w);

    // P3-01과 같은 동기식 Reset > Clear > Valid 계약이다.
    // 상승 에지에서 입력을 수락하고 그 에지 직후 곱과 valid_o를 갱신한다.
    always @(posedge clk) begin
        if (!resetn) begin
            product_o <= {(A_WIDTH+B_WIDTH){1'b0}};
            valid_o <= 1'b0;
        end else if (clear_i) begin
            product_o <= {(A_WIDTH+B_WIDTH){1'b0}};
            valid_o <= 1'b0;
        end else begin
            valid_o <= valid_i;
            if (valid_i) begin
                // 곱의 전체 유효 폭은 A_WIDTH+B_WIDTH. 버리는 상위 비트는 부호 확장뿐이다.
                product_o <= product_full_w[A_WIDTH+B_WIDTH-1:0];
            end
        end
    end

    // synthesis translate_off
    initial begin
        if (A_WIDTH < 2 || A_WIDTH > 25 || B_WIDTH < 2 || B_WIDTH > 18)
            $fatal(1, "Require 2<=A_WIDTH<=25 and 2<=B_WIDTH<=18");
    end
    // synthesis translate_on
endmodule
`default_nettype wire
