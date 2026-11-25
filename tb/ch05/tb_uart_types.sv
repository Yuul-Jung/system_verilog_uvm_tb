`timescale 1ns/1ps
// 제05장: SystemVerilog 자료형으로 UART Echo의 입력·출력을 모델링한다.
// 기존 uart_echo_controller는 수정하지 않는다.
// DUT는 조합 논리이므로 클록·리셋·지연된 UART 직렬 비트는 없다.
module tb_uart_types;
    // (추가) 4상태 logic: X/Z를 포함한 신호 검증에 사용한다.
    logic [7:0] rx_data_i;
    logic       rx_valid_i;
    logic       tx_ready_i;
    wire        rx_ready_o;
    wire [7:0]  tx_data_o;
    wire        tx_valid_o;

    // (추가) typedef + enum: 검증 단계 이름을 숫자 대신 타입으로 지정한다.
    typedef enum logic [1:0] {
        CASE_IDLE  = 2'd0,
        CASE_SEND  = 2'd1,
        CASE_STALL = 2'd2,
        CASE_XDATA = 2'd3
    } case_kind_t;

    // (추가) packed struct: 한 번의 스트림 입력을 하나의 값으로 묶는다.
    typedef struct packed {
        logic [7:0] data;
        logic       valid;
        logic       ready;
    } uart_sample_t;

    // (추가) bit는 2상태 값만 저장한다. X/Z를 저장하면 0으로 변환된다.
    bit [7:0] compact_copy;
    logic [7:0] four_state_copy;
    uart_sample_t sample;
    case_kind_t  kind;
    integer checks = 0;
    integer failures = 0;

    // 실제 원본 RTL의 여섯 포트를 이름 그대로 연결한다.
    uart_echo_controller dut (
        .rx_data_i(rx_data_i),
        .rx_valid_i(rx_valid_i),
        .rx_ready_o(rx_ready_o),
        .tx_data_o(tx_data_o),
        .tx_valid_o(tx_valid_o),
        .tx_ready_i(tx_ready_i)
    );

    // (추가) 입력 적용 후 조합 회로가 안정될 시간을 1ns 제공한다.
    // 출력은 rx_ready_o=tx_ready_i, tx_valid_o=rx_valid_i,
    // tx_data_o=rx_data_i의 관계를 그대로 만족해야 한다.
    task automatic run_case(
        input case_kind_t next_kind,
        input uart_sample_t next_sample
    );
        begin
            kind = next_kind;
            sample = next_sample;
            rx_data_i  = sample.data;
            rx_valid_i = sample.valid;
            tx_ready_i = sample.ready;
            #1;

            checks = checks + 1;
            if ((rx_ready_o !== sample.ready) ||
                (tx_valid_o !== sample.valid) ||
                (tx_data_o !== sample.data)) begin
                failures = failures + 1;
                $error("MISMATCH kind=%0d data=%h valid=%b ready=%b",
                    kind, tx_data_o, tx_valid_o, rx_ready_o);
            end else begin
                $display("MATCH kind=%0d data=%h valid=%b ready=%b",
                    kind, tx_data_o, tx_valid_o, rx_ready_o);
            end
        end
    endtask

`ifdef VCD
    // (변경) Icarus 실행에서 VCD 파형을 기록한다.
    initial begin
        $dumpfile("ch05_uart_types.vcd");
        $dumpvars(0, tb_uart_types);
    end
`endif

    initial begin
        $display("=== CH05 SYSTEMVERILOG TYPES START ===");

        // 입력 데이터가 있어도 valid=0이면 전송은 유효하지 않다.
        // (변경) packed struct와 같은 10비트의 연결 표현을 사용한다.
        // data[9:2], valid[1], ready[0] 순서로 구성된다.
        run_case(CASE_IDLE, {8'h00, 1'b0, 1'b1});

        // valid=1, ready=1이면 전송 가능 상태이다. 실제 수락 이벤트를 측정하지 않는다.
        run_case(CASE_SEND, {8'h41, 1'b1, 1'b1});

        // ready=0이면 이 입력 사례에서는 출력 valid와 data가 그대로 전달된다.
        run_case(CASE_STALL, {8'h42, 1'b1, 1'b0});

        // logic과 원본 조합 DUT는 X를 보존하는지 확인할 수 있다.
        run_case(CASE_XDATA, {8'hx5, 1'b1, 1'b1});
        four_state_copy = rx_data_i;
        compact_copy = rx_data_i;

        checks = checks + 1;
        if (four_state_copy !== 8'hx5) begin
            failures = failures + 1;
            $error("4STATE_COPY_MISMATCH");
        end

        checks = checks + 1;
        if (compact_copy !== 8'h05) begin
            failures = failures + 1;
            $error("2STATE_CONVERSION_MISMATCH");
        end

        $display("TYPE logic=%h bit=%h", four_state_copy, compact_copy);
        if (failures == 0) begin
            $display("PASS checks=%0d failures=0", checks);
            $finish;
        end else begin
            $fatal(1, "FAIL checks=%0d failures=%0d", checks, failures);
        end
    end

    initial begin
        #100;
        $fatal(1, "TIMEOUT: testbench did not finish");
    end
endmodule
