`timescale 1ns/1ps
// 제14장: 실제 uart_core의 RX/TX 깊이 16 FIFO를 공개 포트로 검증.
// 내부 카운터는 교육용 관찰에만 사용하며, 정답 판정은 포트 계약 중심.
module tb_uart_fifo_flow;
    localparam integer CLK_HZ=1000000, BAUD=100000, CPB=10;
    reg clk=0, resetn=0, rxd=1;
    wire txd;
    wire [7:0] rx_out_data;
    wire rx_out_valid, tx_in_ready, fe, ov;
    reg rx_out_ready=0, tx_in_valid=0;
    reg [7:0] tx_in_data=0;
    integer accepted=0, received=0, rx_checked=0;
    reg [7:0] expected_tx[0:31];
    reg [7:0] expected_rx[0:31];
    wire [7:0] mon_data;
    wire mon_valid, mon_fe, mon_ov;
    always #5 clk=~clk;

    uart_core #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) dut (
        .clk(clk), .resetn(resetn), .uart_rxd_i(rxd), .uart_txd_o(txd),
        .rx_out_data(rx_out_data), .rx_out_valid(rx_out_valid),
        .rx_out_ready(rx_out_ready), .tx_in_data(tx_in_data),
        .tx_in_valid(tx_in_valid), .tx_in_ready(tx_in_ready),
        .rx_framing_error_o(fe), .rx_overrun_o(ov)
    );
    // 실제 직렬 TX 핀을 독립 UART RX로 복조한다.
    uart_rx #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) monitor (
        .clk(clk), .resetn(resetn), .rx_i(txd),
        .out_data_o(mon_data), .out_valid_o(mon_valid),
        .out_ready_i(1'b1), .framing_error_o(mon_fe), .overrun_o(mon_ov)
    );

    // 입력 바이트를 handshake 때만 수락한다.
    task automatic push_tx(input [7:0] data);
        integer guard;
        begin
            @(negedge clk);
            tx_in_data=data; tx_in_valid=1;
            guard=0;
            while (tx_in_ready !== 1'b1) begin
                @(negedge clk);
                guard=guard+1;
                if (guard>2000) $fatal(1,"FAIL TX_READY_TIMEOUT");
            end
            @(posedge clk);
            accepted=accepted+1;
            @(negedge clk);
            tx_in_valid=0;
        end
    endtask

    // 8N1: start(0), D0~D7, stop(1). LSB부터 전송한다.
    task automatic send_rx(input [7:0] data);
        integer i;
        begin
            @(negedge clk);
            rxd=0;
            repeat(CPB) @(negedge clk);
            for(i=0;i<8;i=i+1) begin
                rxd=data[i];
                repeat(CPB) @(negedge clk);
            end
            rxd=1;
            repeat(CPB) @(negedge clk);
        end
    endtask

    // 모니터는 TX 핀의 실제 바이트와 전송 순서를 검사한다.
    always @(posedge clk) if (resetn && mon_valid) begin
        if (received>=accepted)
            $fatal(1,"FAIL UNEXPECTED_TX");
        if (mon_data !== expected_tx[received])
            $fatal(1,"FAIL TX_ORDER idx=%0d got=%h expected=%h",
                   received,mon_data,expected_tx[received]);
        received=received+1;
    end

    initial begin
        #1000000;
        $fatal(1,"FAIL GLOBAL_TIMEOUT");
    end

    integer i,guard;
    reg [7:0] held;
    initial begin
        $dumpfile("ch14_uart_fifo.vcd");
        $dumpvars(0,tb_uart_fifo_flow);
        repeat(5) @(negedge clk);
        if (tx_in_ready !== 1'b0 || rx_out_valid !== 1'b0)
            $fatal(1,"FAIL RESET_PORTS");
        resetn=1;
        @(negedge clk);
        if (tx_in_ready !== 1'b1) $fatal(1,"FAIL EMPTY_TX_READY");

        // T1: TX FIFO + PHY에 18바이트를 전송해 full/backpressure 경험.
        // 직렬 송신 중에도 FIFO는 입력을 저장한다.
        for(i=0;i<18;i=i+1) begin
            expected_tx[i]=8'h40+i;
            push_tx(8'h40+i);
        end
        guard=0;
        while(received<18) begin
            @(negedge clk);
            guard=guard+1;
            if(guard>CPB*10*22) $fatal(1,"FAIL TX_DRAIN_TIMEOUT");
        end
        if(accepted!=18 || received!=18 || mon_fe || mon_ov)
            $fatal(1,"FAIL TX_TOTAL");
        $display("T1_TX_FIFO_PASS accepted=%0d received=%0d",accepted,received);

        // T2: RX 준비를 내린 상태로 16바이트를 보내 FIFO를 채운다.
        // 포트 rx_out_data는 backpressure 동안 바뀌면 안 된다.
        rx_out_ready=0;
        for(i=0;i<16;i=i+1) begin
            expected_rx[i]=8'h80+i;
            send_rx(8'h80+i);
        end
        repeat(5) @(negedge clk);
        if(rx_out_valid !== 1'b1 || rx_out_data !== 8'h80)
            $fatal(1,"FAIL RX_HEAD");
        held=rx_out_data;
        repeat(5) begin
            @(negedge clk);
            if(rx_out_valid !== 1'b1 || rx_out_data !== held)
                $fatal(1,"FAIL RX_HOLD");
        end
        // RX를 한 바이트씩 수락하면서 데이터와 순서를 비교.
        for(i=0;i<16;i=i+1) begin
            @(negedge clk);
            if(rx_out_valid !== 1'b1 || rx_out_data !== expected_rx[i])
                $fatal(1,"FAIL RX_ORDER idx=%0d",i);
            rx_out_ready=1;
            @(posedge clk);
            rx_checked=rx_checked+1;
            @(negedge clk);
            rx_out_ready=0;
        end
        if(rx_out_valid !== 1'b0 || fe || ov || rx_checked!=16)
            $fatal(1,"FAIL RX_DRAIN");
        $display("T2_RX_BACKPRESSURE_PASS checked=%0d",rx_checked);

        // T3: Reset 시 FIFO 유효 데이터와 ready 상태 초기화.
        @(negedge clk);
        resetn=0;
        repeat(3) @(negedge clk);
        if(rx_out_valid !== 1'b0 || tx_in_ready !== 1'b0)
            $fatal(1,"FAIL RESET_FLUSH");
        resetn=1;
        @(negedge clk);
        if(tx_in_ready !== 1'b1 || rx_out_valid !== 1'b0)
            $fatal(1,"FAIL RESET_RELEASE");
        $display("T3_RESET_PASS");
        $display("PASS CH14 tx=18 rx=16");
        $finish;
    end
endmodule
