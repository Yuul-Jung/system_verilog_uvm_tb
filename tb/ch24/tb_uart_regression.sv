`timescale 1ns/1ps
// 제24장: 실제 uart_echo_controller 6포트의 시드 기반 반복 회귀 검증.
// 이 DUT는 조합 전달기이므로 클록은 TB 샘플링 기준일 뿐이다.
module tb_uart_regression;
    reg [7:0] rx_data_i = 0;
    reg rx_valid_i = 0;
    reg tx_ready_i = 0;
    wire rx_ready_o, tx_valid_o;
    wire [7:0] tx_data_o;

    uart_echo_controller dut (
        .rx_data_i(rx_data_i), .rx_valid_i(rx_valid_i),
        .rx_ready_o(rx_ready_o), .tx_data_o(tx_data_o),
        .tx_valid_o(tx_valid_o), .tx_ready_i(tx_ready_i)
    );

    integer seed, i, checks = 0, accepted = 0;
    integer cov_idle = 0, cov_stall = 0;
    integer cov_accept = 0, cov_ready_idle = 0;
    integer fault = 0;
    reg [31:0] prng;
    reg [7:0] next_data;
    reg next_valid, next_ready;

    // PRNG(의사난수 생성기): 같은 seed이면 같은 입력 순서를 만든다.
    function automatic [31:0] xorshift32(input [31:0] value);
        reg [31:0] x;
        begin
            x = value ^ (value << 13);
            x = x ^ (x >> 17);
            x = x ^ (x << 5);
            xorshift32 = x;
        end
    endfunction

    // 입력을 안정화한 뒤 4상태 비교로 세 출력의 전달 계약 검사.
    task automatic check_transaction(
        input [7:0] data, input valid, input ready
    );
        begin
            rx_data_i = data;
            rx_valid_i = valid;
            tx_ready_i = ready;
            #1;
            if (tx_data_o !== data || tx_valid_o !== valid ||
                rx_ready_o !== ready)
                $fatal(1, "FAIL PORT_CONTRACT case=%0d", checks);

            if (!valid && !ready) cov_idle = cov_idle + 1;
            if ( valid && !ready) cov_stall = cov_stall + 1;
            if ( valid &&  ready) cov_accept = cov_accept + 1;
            if (!valid &&  ready) cov_ready_idle = cov_ready_idle + 1;
            if (valid && ready) accepted = accepted + 1;
            checks = checks + 1;

            // 오류 주입은 DUT가 아닌 검증기 쪽에만 적용한다.
            // 정상 회귀와 달리 음성 시험은 이 오류를 검출해야 성공한다.
            if (fault && checks == 9)
                $fatal(1, "DETECTED_INJECTED_FAULT case=%0d", checks);
        end
    endtask

    initial begin
        #10000;
        $fatal(1, "FAIL GLOBAL_TIMEOUT");
    end

    initial begin
        if (!$value$plusargs("SEED=%d", seed)) seed = 1;
        if ($test$plusargs("INJECT_FAULT")) fault = 1;
        prng = seed;
        if (prng == 0) prng = 32'h6d2b79f5;

        // 4가지 valid/ready 조합을 반드시 방문한다.
        check_transaction(8'h00, 0, 0);
        check_transaction(8'h41, 1, 0);
        check_transaction(8'h41, 1, 1);
        check_transaction(8'h5a, 0, 1);
        check_transaction(8'hff, 1, 1);
        check_transaction(8'h00, 1, 0);
        check_transaction(8'h0a, 1, 1);
        check_transaction(8'h55, 0, 0);

        // seed별로 24개의 재현 가능한 조합을 추가한다.
        for (i = 0; i < 24; i = i + 1) begin
            prng = xorshift32(prng);
            next_data = prng[15:8];
            next_valid = prng[0];
            next_ready = prng[1];
            check_transaction(next_data, next_valid, next_ready);
        end

        if (checks != 32 || cov_idle == 0 || cov_stall == 0 ||
            cov_accept == 0 || cov_ready_idle == 0)
            $fatal(1, "FAIL COVERAGE checks=%0d", checks);
        $display("COVERAGE seed=%0d idle=%0d stall=%0d accept=%0d ready_idle=%0d",
                 seed, cov_idle, cov_stall, cov_accept, cov_ready_idle);
        $display("PASS CH24 seed=%0d checks=%0d accepted=%0d", seed, checks, accepted);
        $finish;
    end
endmodule
