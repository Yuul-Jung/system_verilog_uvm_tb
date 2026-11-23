// (변경) 8N1 PHY 내부에 깊이 16 RX/TX FIFO를 넣어 byte stream ready/valid를 보존.
// 1바이트 UART 수신 레지스터와 FIFO는 별개. Controller는 stop-and-wait 정책을 유지.
module uart_core #(
    parameter integer CLK_HZ=100000000,BAUD=115200
)(
    input wire clk,resetn,uart_rxd_i,
    output wire uart_txd_o,
    output wire [7:0] rx_out_data,
    output wire rx_out_valid,
    input wire rx_out_ready,
    input wire [7:0] tx_in_data,
    input wire tx_in_valid,
    output wire tx_in_ready,
    output wire rx_framing_error_o,rx_overrun_o
);
    wire [7:0] phy_rx_data;
    wire phy_rx_valid,phy_rx_ready;
    wire [7:0] phy_tx_data;
    wire phy_tx_valid,phy_tx_ready;
    uart_rx #(.CLK_HZ(CLK_HZ),.BAUD(BAUD)) rx(
        .clk(clk),.resetn(resetn),.rx_i(uart_rxd_i),
        .out_data_o(phy_rx_data),.out_valid_o(phy_rx_valid),
        .out_ready_i(phy_rx_ready),.framing_error_o(rx_framing_error_o),
        .overrun_o(rx_overrun_o));
    uart_tx #(.CLK_HZ(CLK_HZ),.BAUD(BAUD)) tx(
        .clk(clk),.resetn(resetn),.in_data_i(phy_tx_data),
        .in_valid_i(phy_tx_valid),.in_ready_o(phy_tx_ready),.tx_o(uart_txd_o));

    reg [7:0] rx_fifo[0:15];
    reg [3:0] rx_wptr,rx_rptr;
    reg [4:0] rx_count;
    wire rx_pop=rx_out_valid && rx_out_ready;
    wire rx_push=phy_rx_valid && phy_rx_ready;
    assign rx_out_valid=(rx_count!=0);
    assign rx_out_data=rx_fifo[rx_rptr];
    assign phy_rx_ready=resetn && ((rx_count<16) || rx_pop);

    reg [7:0] tx_fifo[0:15];
    reg [3:0] tx_wptr,tx_rptr;
    reg [4:0] tx_count;
    wire tx_pop=phy_tx_ready && phy_tx_valid;
    wire tx_push=tx_in_valid && tx_in_ready;
    assign tx_in_ready=resetn && ((tx_count<16) || tx_pop);
    assign phy_tx_valid=(tx_count!=0);
    assign phy_tx_data=tx_fifo[tx_rptr];

    always @(posedge clk)begin
        if(!resetn)begin
            rx_wptr<=0;rx_rptr<=0;rx_count<=0;
            tx_wptr<=0;tx_rptr<=0;tx_count<=0;
        end else begin
            if(rx_push)begin
                rx_fifo[rx_wptr]<=phy_rx_data;
                rx_wptr<=rx_wptr+1'b1;
            end
            if(rx_pop)rx_rptr<=rx_rptr+1'b1;
            case({rx_push,rx_pop})
                2'b10:rx_count<=rx_count+1'b1;
                2'b01:rx_count<=rx_count-1'b1;
                default:begin end
            endcase
            if(tx_push)begin
                tx_fifo[tx_wptr]<=tx_in_data;
                tx_wptr<=tx_wptr+1'b1;
            end
            if(tx_pop)tx_rptr<=tx_rptr+1'b1;
            case({tx_push,tx_pop})
                2'b10:tx_count<=tx_count+1'b1;
                2'b01:tx_count<=tx_count-1'b1;
                default:begin end
            endcase
        end
    end
endmodule
