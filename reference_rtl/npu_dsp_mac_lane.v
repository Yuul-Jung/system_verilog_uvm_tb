// (추가) 02장 등록 DSP 곱을 다음 에지에 누산한다. 곱을 다시 수행하지 않는다.
module npu_dsp_mac_lane #(
    parameter integer DATA_WIDTH=16,
    parameter integer ACC_WIDTH=40
)(
    input wire clk,resetn,clear_i,valid_i,
    input wire signed [DATA_WIDTH-1:0] x_i,w_i,
    output reg signed [ACC_WIDTH-1:0] acc_o
);
    wire signed [2*DATA_WIDTH-1:0] product;
    wire product_valid;
    dsp_multiplier #(.A_WIDTH(DATA_WIDTH),.B_WIDTH(DATA_WIDTH)) dsp(
        .clk(clk),.resetn(resetn),.clear_i(clear_i),
        .valid_i(valid_i),.a_i(x_i),.b_i(w_i),
        .product_o(product),.valid_o(product_valid));
    wire signed [ACC_WIDTH-1:0] product_extended =
        {{(ACC_WIDTH-2*DATA_WIDTH){product[2*DATA_WIDTH-1]}},product};
    always @(posedge clk)begin
        if(!resetn || clear_i)acc_o<=0;
        else if(product_valid)acc_o<=acc_o+product_extended;
    end
    // synthesis translate_off
    initial if(ACC_WIDTH<2*DATA_WIDTH)$fatal(1,"ACC_WIDTH too small");
    // synthesis translate_on
endmodule
