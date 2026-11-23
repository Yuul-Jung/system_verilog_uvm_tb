// (추가) 8N1 수신. RX 2FF, start midpoint/bit center, hold/overrun.
module uart_rx #(
    parameter integer CLK_HZ=100000000, BAUD=115200
)(
    input wire clk,resetn,rx_i,
    output reg [7:0] out_data_o,
    output reg out_valid_o,
    input wire out_ready_i,
    output reg framing_error_o,overrun_o
);
    localparam integer CPB=(CLK_HZ+BAUD/2)/BAUD;
    localparam integer HALF=CPB/2;
    localparam [1:0] IDLE=0,START=1,DATA=2,STOP=3;
    reg [1:0] state;
    reg rx_meta,rx_sync;
    reg [31:0] count_q;
    reg [2:0] bit_q;
    reg [7:0] shift_q;
    always @(posedge clk)begin
        if(!resetn)begin
            state<=IDLE;rx_meta<=1;rx_sync<=1;count_q<=0;bit_q<=0;shift_q<=0;
            out_data_o<=0;out_valid_o<=0;framing_error_o<=0;overrun_o<=0;
        end else begin
            rx_meta<=rx_i;rx_sync<=rx_meta;
            if(out_valid_o && out_ready_i)out_valid_o<=0;
            case(state)
                IDLE:if(!rx_sync)begin count_q<=HALF-1;state<=START;end
                START:if(count_q==0)begin
                    if(!rx_sync)begin count_q<=CPB-1;bit_q<=0;state<=DATA;end
                    else state<=IDLE;
                end else count_q<=count_q-1'b1;
                DATA:if(count_q==0)begin
                    shift_q[bit_q]<=rx_sync;count_q<=CPB-1;
                    if(bit_q==7)state<=STOP;
                    else bit_q<=bit_q+1'b1;
                end else count_q<=count_q-1'b1;
                STOP:if(count_q==0)begin
                    state<=IDLE;
                    if(!rx_sync)framing_error_o<=1;
                    else if(!out_valid_o || out_ready_i)begin
                        out_data_o<=shift_q;out_valid_o<=1;
                    end else overrun_o<=1;
                end else count_q<=count_q-1'b1;
                default:state<=IDLE;
            endcase
        end
    end
    // synthesis translate_off
    initial if(CPB<4)$fatal(1,"Unsupported UART clock/baud ratio");
    // synthesis translate_on
endmodule
