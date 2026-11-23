`timescale 1ns/1ps
`default_nettype none

// 독립 signed MAC: 보드 및 AXI에 의존하지 않는다.
(* use_dsp = "yes" *)
module mac_core #(
    parameter integer DATA_WIDTH = 16,
    parameter integer ACC_WIDTH = 40
) (
    input wire clk,
    input wire resetn,
    input wire clear_i,
    input wire valid_i,
    input wire signed [DATA_WIDTH-1:0] a_i,
    input wire signed [DATA_WIDTH-1:0] b_i,
    output reg signed [ACC_WIDTH-1:0] acc_o,
    output reg valid_o
);
    localparam integer PRODUCT_WIDTH = 2 * DATA_WIDTH;
    wire signed [PRODUCT_WIDTH-1:0] product_w;
    wire signed [ACC_WIDTH-1:0] product_ext_w;

    // 전체 곱을 보존한 뒤 부호 비트를 복제하여 누산 폭으로 확장한다.
    // 지원 조건: DATA_WIDTH >= 2, ACC_WIDTH >= 2*DATA_WIDTH.
    assign product_w = $signed(a_i) * $signed(b_i);
    assign product_ext_w = {{(ACC_WIDTH-PRODUCT_WIDTH){product_w[PRODUCT_WIDTH-1]}}, product_w};

    // 동기식 Active-Low Reset > Clear > Valid 순서.
    // 입력을 수락한 상승 에지 직후 acc_o와 valid_o가 함께 갱신된다.
    // valid_i=0이면 acc_o 유지, valid_o=0. Clear와 겹친 입력은 버린다.
    always @(posedge clk) begin
        if (!resetn) begin
            acc_o <= {ACC_WIDTH{1'b0}};
            valid_o <= 1'b0;
        end else if (clear_i) begin
            acc_o <= {ACC_WIDTH{1'b0}};
            valid_o <= 1'b0;
        end else begin
            valid_o <= valid_i;
            if (valid_i)
                // 범위 초과 시 상위 비트를 버리는 2의 보수 순환 연산이다.
                acc_o <= acc_o + product_ext_w;
        end
    end

    // synthesis translate_off
    initial begin
        if (DATA_WIDTH < 2 || ACC_WIDTH < PRODUCT_WIDTH)
            $fatal(1, "Require DATA_WIDTH>=2 and ACC_WIDTH>=2*DATA_WIDTH");
    end
    // synthesis translate_on
endmodule
`default_nettype wire
