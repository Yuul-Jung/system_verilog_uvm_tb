`timescale 1ns/1ps
// 제01장: 기존 UART Echo Controller의 입출력을 관찰하는 첫 테스트벤치.
// 이 단계는 출력 표시가 목적이며, 자동 PASS/FAIL은 제04장에서 학습한다.
module tb_uart_echo_basics;
    // TB가 직접 구동하는 DUT 입력은 reg로 선언한다.
    reg  [7:0] rx_data_i;
    reg        rx_valid_i;
    reg        tx_ready_i;

    // DUT가 구동하는 출력은 wire로 관찰한다.
    wire       rx_ready_o;
    wire [7:0] tx_data_o;
    wire       tx_valid_o;

    // 기존 RTL의 실제 포트 이름과 1:1로 연결한다.
    uart_echo_controller dut (
        .rx_data_i (rx_data_i),
        .rx_valid_i(rx_valid_i),
        .rx_ready_o(rx_ready_o),
        .tx_data_o (tx_data_o),
        .tx_valid_o(tx_valid_o),
        .tx_ready_i(tx_ready_i)
    );

`ifdef VCD
    // Icarus Verilog 사용 시 -DVCD 옵션으로 파형 저장 기능을 켠다.
    initial begin
        $dumpfile("ch01_uart_echo.vcd");
        $dumpvars(0, tb_uart_echo_basics);
    end
`endif

    initial begin
        $display("=== CH01 UART ECHO TESTBENCH START ===");

        // 10ns: 유효 데이터가 없고 송신 준비도 안 된 상태.
        rx_data_i  = 8'h00;
        rx_valid_i = 1'b0;
        tx_ready_i = 1'b0;
        #10;
        $display("t=%0d ns rx=%02h rv=%b tr=%b | tx=%02h tv=%b rr=%b",
            $time, rx_data_i, rx_valid_i, tx_ready_i,
            tx_data_o, tx_valid_o, rx_ready_o);

        // 20ns: 문자 'A'(ASCII 0x41)를 정상 전달한다.
        rx_data_i  = 8'h41;
        rx_valid_i = 1'b1;
        tx_ready_i = 1'b1;
        #10;
        $display("t=%0d ns rx=%02h rv=%b tr=%b | tx=%02h tv=%b rr=%b",
            $time, rx_data_i, rx_valid_i, tx_ready_i,
            tx_data_o, tx_valid_o, rx_ready_o);

        // 30ns: 뒤쪽 준비 신호를 내려 전송 대기를 관찰한다.
        rx_data_i  = 8'h5A;
        rx_valid_i = 1'b1;
        tx_ready_i = 1'b0;
        #10;
        $display("t=%0d ns rx=%02h rv=%b tr=%b | tx=%02h tv=%b rr=%b",
            $time, rx_data_i, rx_valid_i, tx_ready_i,
            tx_data_o, tx_valid_o, rx_ready_o);

        // 40ns: 유효 데이터 없이 준비 신호만 켠다.
        rx_data_i  = 8'h00;
        rx_valid_i = 1'b0;
        tx_ready_i = 1'b1;
        #10;
        $display("t=%0d ns rx=%02h rv=%b tr=%b | tx=%02h tv=%b rr=%b",
            $time, rx_data_i, rx_valid_i, tx_ready_i,
            tx_data_o, tx_valid_o, rx_ready_o);

        $display("=== CH01 END: OBSERVATION ONLY ===");
        $finish;
    end
endmodule
