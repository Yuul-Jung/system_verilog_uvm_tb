`timescale 1ns/1ps
// 제13장: 기존 조합형 UART Echo Controller의 Byte Stream BFM 검증.
// 주의: 이 DUT는 UART 직렬 비트 프레임을 해독하지 않는다.
// 이 장의 '프레임'은 TB가 구성하는 바이트 거래 시퀀스이다.
module tb_uart_stream;
    reg [7:0] rx_data_i = 8'h00;
    reg rx_valid_i = 1'b0;
    reg tx_ready_i = 1'b0;
    wire rx_ready_o, tx_valid_o;
    wire [7:0] tx_data_o;
    integer checks = 0;
    integer accepted = 0;
    // (추가) 모든 샘플 에지를 감시하는 독립 모니터 상태.
    integer stalled = 0, unknown_ready = 0;
    reg previous_stall = 1'b0;
    reg [7:0] held_data;

    uart_echo_controller dut (
        .rx_data_i(rx_data_i), .rx_valid_i(rx_valid_i),
        .rx_ready_o(rx_ready_o), .tx_data_o(tx_data_o),
        .tx_valid_o(tx_valid_o), .tx_ready_i(tx_ready_i)
    );

    // TB 가상 샘플 클록: DUT에 연결되지 않는다.
    reg tb_clk = 0;
    always #5 tb_clk = ~tb_clk;

    // (추가) 수락 카운트는 BFM이 아니라 매 상승 에지 모니터가 관리한다.
    always @(posedge tb_clk) begin
        if (tx_data_o !== rx_data_i || tx_valid_o !== rx_valid_i ||
            rx_ready_o !== tx_ready_i)
            $fatal(1, "FAIL MONITOR_PORTS");
        // 직전 샘플에서 대기했다면 다음 샘플까지 데이터와 valid를 유지.
        if (previous_stall &&
            (tx_valid_o !== 1'b1 || tx_data_o !== held_data))
            $fatal(1, "FAIL HOLD");
        previous_stall = 1'b0;
        if (tx_valid_o === 1'b1) begin
            case (tx_ready_i)
                1'b0: begin
                    stalled++;
                    previous_stall = 1'b1;
                    held_data = tx_data_o;
                end
                1'b1: begin
                    case (accepted)
                        0: if (tx_data_o !== 8'h41) $fatal(1, "FAIL ORDER A");
                        1: if (tx_data_o !== 8'h5A) $fatal(1, "FAIL ORDER Z");
                        2: if (tx_data_o !== 8'h0A) $fatal(1, "FAIL ORDER LF");
                        default: $fatal(1, "FAIL EXTRA_ACCEPT");
                    endcase
                    accepted++;
                    $display("ACCEPT t=%0d ns data=%h", $time, tx_data_o);
                end
                default: unknown_ready++; // X/Z는 확정 수락이 아니다.
            endcase
        end
    end

    // 조합회로 안정화 후 모든 공개 출력의 4상태 비교.
    task automatic expect_ports(
        input [7:0] data, input valid, input ready
    );
        begin
            #1;
            if (tx_data_o !== data || tx_valid_o !== valid ||
                rx_ready_o !== ready)
                $fatal(1, "FAIL data=%h valid=%b ready=%b", 
                       tx_data_o, tx_valid_o, rx_ready_o);
            checks = checks + 1;
        end
    endtask

    // BFM: 입력 바이트를 준비하고, 준비가 돌아올 때까지 유지한다.
    // stall_cycles는 수락 이전에 ready=0으로 유지할 샘플 수.
    task automatic send_byte(
        input [7:0] data, input integer stall_cycles
    );
        integer k;
        begin
            @(negedge tb_clk);
            rx_data_i = data;
            rx_valid_i = 1'b1;
            tx_ready_i = 1'b0;
            for (k = 0; k < stall_cycles; k = k + 1) begin
                expect_ports(data, 1'b1, 1'b0);
                @(posedge tb_clk);
                if (rx_ready_o !== 1'b0)
                    $fatal(1, "FAIL stall handshake");
                @(negedge tb_clk);
            end
            tx_ready_i = 1'b1;
            expect_ports(data, 1'b1, 1'b1);
            @(posedge tb_clk);
            // (변경) 수락과 순서는 독립 상승 에지 모니터가 판정한다.
            if (rx_valid_i !== 1'b1 || rx_ready_o !== 1'b1)
                $fatal(1, "FAIL acceptance");
            @(negedge tb_clk);
            rx_valid_i = 1'b0;
            expect_ports(data, 1'b0, 1'b1);
        end
    endtask

    initial begin
        #2000;
        $fatal(1, "FAIL GLOBAL_TIMEOUT");
    end

`ifdef VCD
    // (변경) Icarus에서 조건부 파형 기록.
    initial begin
        $dumpfile("ch13_uart_stream.vcd");
        $dumpvars(0, tb_uart_stream);
    end
`endif
    initial begin
        // 비활성 상태: valid=0이면 데이터가 있어도 거래가 아니다.
        expect_ports(8'h00, 1'b0, 1'b0);
        // 문자 A, Z, 줄바꿈: 3바이트 프레임의 교육용 표현.
        send_byte(8'h41, 0);
        send_byte(8'h5A, 2);
        send_byte(8'h0A, 1);
        // UART 물리 계층의 패리티/프레이밍 오류는 이 DUT에 포트가 없다.
        // 대신 준비 신호의 비정상 X 전파를 관찰하는 시험.
        @(negedge tb_clk);
        rx_valid_i = 1'b1;
        rx_data_i = 8'h45;
        tx_ready_i = 1'bx;
        expect_ports(8'h45, 1'b1, 1'bx);
        @(negedge tb_clk);
        rx_valid_i = 1'b0;
        tx_ready_i = 1'b0;
        expect_ports(8'h45, 1'b0, 1'b0);
        // (추가) 고임피던스 Z도 전파되며 확정 수락되지 않는다.
        @(negedge tb_clk);
        rx_valid_i = 1'b1;
        rx_data_i = 8'h46;
        tx_ready_i = 1'bz;
        expect_ports(8'h46, 1'b1, 1'bz);
        @(negedge tb_clk);
        rx_valid_i = 1'b0;
        tx_ready_i = 1'b0;
        expect_ports(8'h46, 1'b0, 1'b0);
        if (stalled != 3 || unknown_ready != 2 || previous_stall)
            $fatal(1, "FAIL monitor counts");
        if (accepted != 3 || checks != 14)
            $fatal(1, "FAIL count accepted=%0d checks=%0d", accepted, checks);
        $display("MONITOR stalled=%0d unknown_ready=%0d", stalled, unknown_ready);
        $display("PASS CH13 accepted=%0d checks=%0d", accepted, checks);
        $finish;
    end
endmodule
