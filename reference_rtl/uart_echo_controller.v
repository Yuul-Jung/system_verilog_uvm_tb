// (추가) 준비 단계 UART Echo controller: pure combinational stream transfer.
module uart_echo_controller(
    input wire [7:0] rx_data_i,
    input wire rx_valid_i,
    output wire rx_ready_o,
    output wire [7:0] tx_data_o,
    output wire tx_valid_o,
    input wire tx_ready_i
);
    assign rx_ready_o=tx_ready_i;
    assign tx_valid_o=rx_valid_i;
    assign tx_data_o=rx_data_i;
endmodule
