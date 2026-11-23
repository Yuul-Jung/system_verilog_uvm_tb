`timescale 1ns/1ps
// 제06장: packed/unpacked 배열, queue, package로 UART Echo 기대값을 관리.
// 실제 DUT는 조합 회로이며 UART 직렬 전송기나 FIFO가 아니다.
module tb_uart_arrays_queues;
    import uart_expect_pkg::*;

    logic [7:0] rx_data_i;
    logic       rx_valid_i;
    logic       tx_ready_i;
    wire [7:0]  tx_data_o;
    wire        tx_valid_o;
    wire        rx_ready_o;

    // 실제 원본의 여섯 포트를 정확한 이름으로 연결한다.
    uart_echo_controller dut (
        .rx_data_i(rx_data_i),
        .rx_valid_i(rx_valid_i),
        .rx_ready_o(rx_ready_o),
        .tx_data_o(tx_data_o),
        .tx_valid_o(tx_valid_o),
        .tx_ready_i(tx_ready_i)
    );

    // packed 배열: 4개 바이트를 하나의 32비트 벡터로 저장한다.
    logic [3:0][7:0] packed_bytes;
    // unpacked 배열: 4개의 독립된 8비트 원소를 보관한다.
    logic [7:0] unpacked_bytes [0:3];

    // queue: 기대되는 출력 데이터를 입력 순서대로 보관한다.
    // 원본 DUT 내부에 FIFO가 있다는 뜻이 아니다.
    logic [7:0] expected_q[$];
    uart_sample_t sample;
    case_kind_t kind;
    logic [7:0] expected_byte;
    integer checks = 0;
    integer failures = 0;
    integer i;

    // 전송은 valid와 ready가 모두 1일 때에만 수락된다.
    task automatic apply_sample(
        input case_kind_t next_kind,
        input uart_sample_t next_sample
    );
        begin
            kind = next_kind;
            sample = next_sample;

            rx_data_i  = sample.data;
            rx_valid_i = sample.valid;
            tx_ready_i = sample.ready;
            #1; // 조합 전파 관찰용 시간, 실제 DUT 레이턴시 아님.

            checks = checks + 1;
            if ((tx_data_o !== sample.data) ||
                (tx_valid_o !== sample.valid) ||
                (rx_ready_o !== sample.ready)) begin
                failures = failures + 1;
                $error("SIGNAL_MISMATCH kind=%0d data=%h", kind, sample.data);
            end

            if (sample.valid && sample.ready) begin
                if (expected_q.size() == 0) begin
                    failures = failures + 1;
                    $error("QUEUE_UNDERFLOW kind=%0d", kind);
                end else begin
                    expected_byte = expected_q.pop_front();
                    checks = checks + 1;
                    if (tx_data_o !== expected_byte) begin
                        failures = failures + 1;
                        $error("DATA_MISMATCH got=%h expected=%h",
                            tx_data_o, expected_byte);
                    end else begin
                        $display("ACCEPT t=%0t data=%h remain=%0d",
                            $time, tx_data_o, expected_q.size());
                    end
                end
            end else begin
                $display("HOLD t=%0t kind=%0d valid=%b ready=%b",
                    $time, kind, sample.valid, sample.ready);
            end
        end
    endtask

    initial begin
        $dumpfile("ch06_uart_arrays_queues.vcd");
        $dumpvars(0, tb_uart_arrays_queues);
    end

    initial begin
        rx_data_i  = 8'h00;
        rx_valid_i = 1'b0;
        tx_ready_i = 1'b0;
        packed_bytes = {8'h41, 8'h42, 8'h43, 8'h44};

        // packed 인덱스 3은 최상위 바이트(41), 인덱스 0은 44.
        for (i = 0; i < 4; i = i + 1)
            unpacked_bytes[i] = packed_bytes[3-i];

        // 아직 전송 전이므로 예상값 네 개를 큐에 먼저 쌓는다.
        for (i = 0; i < 4; i = i + 1)
            expected_q.push_back(unpacked_bytes[i]);

        $display("=== CH06 ARRAYS QUEUES PACKAGES START ===");
        $display("ARRAY packed=%h first=%h last=%h",
            packed_bytes, unpacked_bytes[0], unpacked_bytes[3]);
        $display("QUEUE size=%0d", expected_q.size());

        // 유효하지 않은 데이터: queue에서 꺼내지 않는다.
        apply_sample(CASE_IDLE, '{1'b0, 1'b1, 8'h00});

        // A는 수락, B는 ready=0인 동안 수락하지 않는다.
        apply_sample(CASE_SEND, '{1'b1, 1'b1, 8'h41});
        apply_sample(CASE_STALL, '{1'b1, 1'b0, 8'h42});
        apply_sample(CASE_RESUME, '{1'b1, 1'b1, 8'h42});

        // C, D를 이어서 전송하고 큐를 비운다.
        apply_sample(CASE_SEND, '{1'b1, 1'b1, 8'h43});
        apply_sample(CASE_SEND, '{1'b1, 1'b1, 8'h44});

        checks = checks + 1;
        if (expected_q.size() != 0) begin
            failures = failures + 1;
            $error("QUEUE_NOT_EMPTY remain=%0d", expected_q.size());
        end

        if (failures == 0) begin
            $display("PASS checks=%0d failures=0 queue=0", checks);
            $finish;
        end else begin
            $fatal(1, "FAIL checks=%0d failures=%0d", checks, failures);
        end
    end

    // wait 없이 종료되도록 전체 시간 상한을 별도로 설정한다.
    initial begin
        #100;
        $fatal(1, "TIMEOUT: testbench did not finish");
    end
endmodule
