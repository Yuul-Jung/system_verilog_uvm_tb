// (추가) 8N1 송신. valid/ready handshake, 10bit start/data/stop.
module uart_tx #(
    parameter integer CLK_HZ=100000000, BAUD=115200
)(
    input wire clk,resetn,
    input wire [7:0] in_data_i,
    input wire in_valid_i,
    output wire in_ready_o,
    output reg tx_o
);
    localparam integer CPB=(CLK_HZ+BAUD/2)/BAUD;
    reg sending;
    reg [31:0] tick_q;
    reg [3:0] bit_q;
    reg [9:0] frame_q;
    assign in_ready_o=resetn && !sending;
    always @(posedge clk)begin
        if(!resetn)begin
            sending<=0;tick_q<=0;bit_q<=0;frame_q<=10'h3ff;tx_o<=1;
        end else if(!sending)begin
            tx_o<=1;
            if(in_valid_i)begin
                sending<=1;tick_q<=CPB-1;bit_q<=0;
                frame_q<={1'b1,in_data_i,1'b0};tx_o<=0;
            end
        end else if(tick_q!=0)tick_q<=tick_q-1'b1;
        else begin
            tick_q<=CPB-1;frame_q<={1'b1,frame_q[9:1]};
            if(bit_q==9)begin sending<=0;tx_o<=1;end
            else begin bit_q<=bit_q+1'b1;tx_o<=frame_q[1];end
        end
    end
    // synthesis translate_off
    initial if(CPB<4)$fatal(1,"Unsupported UART clock/baud ratio");
    // synthesis translate_on
endmodule
