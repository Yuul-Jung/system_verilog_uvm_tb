`timescale 1ns/1ps
`default_nettype none

// 곱 레지스터와 누산 레지스터를 분리한 독립 MAC. k 입력 → k+1 출력.
(* use_dsp = "yes" *)
module mac_pipeline_core #(
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
    reg signed [PRODUCT_WIDTH-1:0] product_q;
    reg product_valid_q;
    wire signed [ACC_WIDTH-1:0] product_ext_w;

    assign product_w = $signed(a_i) * $signed(b_i);
    assign product_ext_w = {{(ACC_WIDTH-PRODUCT_WIDTH){product_q[PRODUCT_WIDTH-1]}}, product_q};

    always @(posedge clk) begin
        if (!resetn) begin
            product_q <= {PRODUCT_WIDTH{1'b0}};
            product_valid_q <= 1'b0;
            acc_o <= {ACC_WIDTH{1'b0}};
            valid_o <= 1'b0;
        end else if (clear_i) begin
            // 현재 입력과 미누산 곱을 모두 버려 지연 Valid가 남지 않게 한다.
            product_q <= {PRODUCT_WIDTH{1'b0}};
            product_valid_q <= 1'b0;
            acc_o <= {ACC_WIDTH{1'b0}};
            valid_o <= 1'b0;
        end else begin
            // 1단계: 곱과 같은 에지의 Valid를 함께 저장한다.
            product_valid_q <= valid_i;
            if (valid_i) begin
                product_q <= product_w;
            end
            // 2단계: 비차단 대입은 이전 에지에 저장된 곱과 Valid를 참조한다.
            valid_o <= product_valid_q;
            if (product_valid_q) begin
                // 부호 확장 후 더하며 범위 초과는 P3-01과 같은 2의 보수 순환이다.
                acc_o <= acc_o + product_ext_w;
            end
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
