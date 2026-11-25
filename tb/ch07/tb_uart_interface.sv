`timescale 1ns/1ps
// 제07장: interface → modport → clocking block → 기존 UART Echo 검증.
// uart_echo_controller.v 원본은 읽기 전용으로 컴파일한다.

// (추가) 기능 없이 기존 DUT 포트를 interface 신호로만 연결하는 Wrapper.
module uart_echo_bind(uart_stream_if.DUT bus);
    uart_echo_controller dut (
        .rx_data_i (bus.rx_data_i),
        .rx_valid_i(bus.rx_valid_i),
        .rx_ready_o(bus.rx_ready_o),
        .tx_data_o (bus.tx_data_o),
        .tx_valid_o(bus.tx_valid_o),
        .tx_ready_i(bus.tx_ready_i)
    );
endmodule

// (추가) TB modport를 통해서 clocking block 신호만 접근한다.
module uart_stream_agent(uart_stream_if.TB bus);
    integer checked;

    // 출력과 기대값을 4상태(0, 1, X, Z)까지 포함하여 비교한다.
    // 제04장에서 배운 자동 PASS/FAIL 검증을 이번 인터페이스에 재사용한다.
    task automatic check_case(
        input string      case_name,
        input logic [7:0] exp_data,
        input logic       exp_valid,
        input logic       exp_ready
    );
        begin
            if ((bus.cb.tx_data_o !== exp_data) ||
                (bus.cb.tx_valid_o !== exp_valid) ||
                (bus.cb.rx_ready_o !== exp_ready)) begin
                $fatal(1,
                    "FAIL %s: data=%02h valid=%b ready=%b (expected %02h/%b/%b)",
                    case_name,
                    bus.cb.tx_data_o, bus.cb.tx_valid_o, bus.cb.rx_ready_o,
                    exp_data, exp_valid, exp_ready);
            end
            checked = checked + 1;
            $display("PASS %s: data=%02h valid=%b ready=%b",
                case_name,
                bus.cb.tx_data_o, bus.cb.tx_valid_o, bus.cb.rx_ready_o);
        end
    endtask

    initial begin
        checked = 0;
        $display("=== CH07 INTERFACE / MODPORT / CLOCKING START ===");

        // t=5ns: 첫 clocking event 후 A를 구동한다.
        // output #0 때문에 이 에지에서 샘플된 값은 아직 A가 아니다.
        @(bus.cb);
        bus.cb.rx_data_i  <= 8'h41;
        bus.cb.rx_valid_i <= 1'b1;
        bus.cb.tx_ready_i <= 1'b1;

        // t=15ns: 앞선 주기 A/valid/ready가 샘플된 것을 확인한다.
        @(bus.cb);
        check_case("A_ACCEPT", 8'h41, 1'b1, 1'b1);

        // t=15ns 이후: Z를 제시하지만 수신 준비를 내린다.
        bus.cb.rx_data_i  <= 8'h5A;
        bus.cb.rx_valid_i <= 1'b1;
        bus.cb.tx_ready_i <= 1'b0;

        // t=25ns: 정지(backpressure) 중에는 ready=0이다.
        @(bus.cb);
        check_case("Z_STALL", 8'h5A, 1'b1, 1'b0);

        // (중요) 수락될 때까지 Z와 valid=1을 유지한다.
        bus.cb.tx_ready_i <= 1'b1;

        // t=35ns: 동일한 Z 데이터가 정상 수락된 것을 확인한다.
        @(bus.cb);
        check_case("Z_ACCEPT", 8'h5A, 1'b1, 1'b1);
        bus.cb.rx_valid_i <= 1'b0;

        // t=45ns: valid가 없으므로 데이터 값은 있어도 전송하지 않는다.
        @(bus.cb);
        check_case("IDLE", 8'h5A, 1'b0, 1'b1);

        $display("CH07 PASS: %0d cases checked", checked);
        $finish;
    end
endmodule

// (추가) DUT에는 클록을 연결하지 않는다.
// tb_clk은 오직 테스트벤치의 구동·관찰 경계를 정의한다.
module tb_uart_interface;
    logic tb_clk = 1'b0;
    always #5 tb_clk = ~tb_clk;

    uart_stream_if   stream(tb_clk);
    uart_echo_bind   adapter(stream);
    uart_stream_agent agent(stream);

`ifdef VCD
    // (변경) Verilator 실행 시 파형 기록을 활성화한다.
    initial begin
        $dumpfile("ch07_uart_interface.vcd");
        $dumpvars(0, tb_uart_interface);
    end
`endif

    // 정지 상태나 입력 오류로 무한 대기할 때 검사한다.
    initial begin
        #200;
        $fatal(1, "CH07 TIMEOUT: clocking block sequence did not finish");
    end
endmodule
