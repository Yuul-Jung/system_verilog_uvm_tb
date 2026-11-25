`timescale 1ns/1ps
// 제14장: 실제 uart_core의 RX/TX 깊이 16 FIFO를 공개 포트로 검증.
// 내부 카운터는 교육용 관찰에만 사용하며, 정답 판정은 포트 계약 중심.
module tb_uart_fifo_flow;
    localparam integer CLK_HZ=100000000, BAUD=10000000, CPB=10;
    reg clk=0, resetn=0, rxd=1;
    wire txd;
    wire [7:0] rx_out_data;
    wire rx_out_valid, tx_in_ready, fe, ov;
    reg rx_out_ready=0, tx_in_valid=0;
    reg [7:0] tx_in_data=0;
    integer accepted=0, received=0, rx_checked=0;
    integer phase=0, tx_stalls=0, tx_full_swap=0, rx_full_swap=0;
    reg rx_held=0;
    reg [7:0] held_data;
    always #5 clk=~clk;

    uart_core #(.CLK_HZ(CLK_HZ), .BAUD(BAUD)) dut (
        .clk(clk), .resetn(resetn), .uart_rxd_i(rxd), .uart_txd_o(txd),
        .rx_out_data(rx_out_data), .rx_out_valid(rx_out_valid),
        .rx_out_ready(rx_out_ready), .tx_in_data(tx_in_data),
        .tx_in_valid(tx_in_valid), .tx_in_ready(tx_in_ready),
        .rx_framing_error_o(fe), .rx_overrun_o(ov)
    );
    // (변경) 실제 상승 에지의 거래를 독립 집계한다.
    // 내부 count는 경계 발생 및 용량 검사의 보조 증거로 사용한다.
    always @(posedge clk) begin
        if (!resetn) rx_held=0;
        else begin
            if ((^dut.rx_count) === 1'bx || (^dut.tx_count) === 1'bx ||
                dut.rx_count>16 || dut.tx_count>16)
                $fatal(1,"FAIL FIFO_COUNT");
            if (phase==1 && tx_in_valid) begin
                if (tx_in_ready === 1'b0) tx_stalls++;
                if (tx_in_ready === 1'b1) begin
                    if (accepted>=18 || tx_in_data !== (8'h40+8'(accepted)))
                        $fatal(1,"FAIL TX_ACCEPT_ORDER");
                    accepted++;
                    if (dut.tx_count==16 && dut.tx_pop) tx_full_swap++;
                end
            end
            if (rx_held && (rx_out_valid !== 1'b1 || rx_out_data !== held_data))
                $fatal(1,"FAIL RX_HOLD");
            rx_held=(rx_out_valid === 1'b1 && rx_out_ready === 1'b0);
            if (rx_held) held_data=rx_out_data;
            if ((phase==2 || phase==3) &&
                rx_out_valid === 1'b1 && rx_out_ready === 1'b1) begin
                if (rx_checked>=((phase==2)?16:17) ||
                    rx_out_data !== ((phase==2?8'h80:8'ha0)+8'(rx_checked)))
                    $fatal(1,"FAIL RX_ORDER phase=%0d idx=%0d",phase,rx_checked);
                rx_checked++;
                if (phase==3 && dut.rx_count==16 && dut.rx_push)
                    rx_full_swap++;
            end
        end
    end

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
            if (tx_in_ready !== 1'b1) $fatal(1,"FAIL TX_HANDSHAKE");
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

    // (변경) DUT의 uart_rx를 재사용하지 않는 독립 8N1 복조기.
    // TX 시작 에지 이후 각 비트 중앙 부근에서 직접 관찰한다.
    reg [7:0] decoded;
    integer frame_index, bit_index;
    initial begin
        wait(phase==1);
        for(frame_index=0;frame_index<18;frame_index++) begin
            @(negedge txd);
            repeat(CPB/2) @(negedge clk);
            if(txd !== 1'b0) $fatal(1,"FAIL TX_START");
            for(bit_index=0;bit_index<8;bit_index++) begin
                repeat(CPB) @(negedge clk);
                decoded[bit_index]=txd;
            end
            repeat(CPB) @(negedge clk);
            if(txd !== 1'b1) $fatal(1,"FAIL TX_STOP");
            if(received>=accepted || decoded !== (8'h40+8'(frame_index)))
                $fatal(1,"FAIL TX_ORDER idx=%0d got=%h",frame_index,decoded);
            received++;
        end
    end

    task automatic drain_rx(input integer total);
        integer k;
        begin
            for(k=0;k<total;k++) begin
                @(negedge clk);
                if(rx_out_valid !== 1'b1) $fatal(1,"FAIL RX_EMPTY_EARLY");
                rx_out_ready=1;
                @(negedge clk); rx_out_ready=0;
            end
            if(rx_out_valid !== 1'b0 || rx_checked!=total)
                $fatal(1,"FAIL RX_DRAIN");
        end
    endtask

    initial begin
        #1000000;
        $fatal(1,"FAIL GLOBAL_TIMEOUT");
    end

`ifdef VCD
    initial begin
        $dumpfile("ch14_uart_fifo.vcd");
        $dumpvars(0,tb_uart_fifo_flow);
    end
`endif
    integer i,guard;
    initial begin
        repeat(5) @(negedge clk);
        if(tx_in_ready !== 1'b0 || rx_out_valid !== 1'b0 ||
           txd !== 1'b1 || fe !== 1'b0 || ov !== 1'b0)
            $fatal(1,"FAIL RESET_PORTS");
        resetn=1;
        @(negedge clk);
        if(tx_in_ready !== 1'b1) $fatal(1,"FAIL EMPTY_TX_READY");

        // (변경) T1: 16 FIFO + 1 PHY를 초과하는 18개 입력.
        phase=1;
        for(i=0;i<18;i++) push_tx(8'h40+8'(i));
        guard=0;
        while(received<18) begin
            @(negedge clk); guard++;
            if(guard>CPB*10*22) $fatal(1,"FAIL TX_DRAIN_TIMEOUT");
        end
        repeat(CPB*20) begin
            @(negedge clk);
            if(txd !== 1'b1) $fatal(1,"FAIL EXTRA_TX");
        end
        if(accepted!=18 || received!=18 || tx_stalls==0 ||
           tx_full_swap==0 || dut.tx_count !== 5'd0)
            $fatal(1,"FAIL TX_TOTAL_OR_BOUNDARY");
        $display("T1_TX_FIFO_PASS accepted=18 received=18");

        // T2: ready=0으로 RX 16개 저장, 대기 유지 및 순서 검사.
        phase=2;
        for(i=0;i<16;i++) send_rx(8'h80+8'(i));
        repeat(5) @(negedge clk);
        if(dut.rx_count !== 5'd16 || rx_out_valid !== 1'b1 ||
           rx_out_data !== 8'h80 || fe !== 1'b0 || ov !== 1'b0)
            $fatal(1,"FAIL RX_FULL");
        drain_rx(16);
        $display("T2_RX_BACKPRESSURE_PASS checked=16");

        // (추가) T3: FIFO 16 + PHY 보류 1, 18번째 overrun.
        phase=3; rx_checked=0;
        for(i=0;i<18;i++) send_rx(8'ha0+8'(i));
        repeat(5) @(negedge clk);
        if(dut.rx_count !== 5'd16 || dut.phy_rx_valid !== 1'b1 ||
           rx_out_data !== 8'ha0 || fe !== 1'b0 || ov !== 1'b1)
            $fatal(1,"FAIL RX_OVERRUN");
        drain_rx(17);
        if(rx_full_swap==0 || ov !== 1'b1 || fe !== 1'b0)
            $fatal(1,"FAIL RX_SWAP_OR_STICKY");
        $display("T3_RX_OVERRUN_PASS kept=17 dropped=1");

        // (변경) T4: FIFO가 실제로 비어 있지 않을 때 리셋.
        phase=4;
        send_rx(8'hc3);
        repeat(5) @(negedge clk);
        push_tx(8'h00); push_tx(8'h11); push_tx(8'h22);
        if(rx_out_valid !== 1'b1 || rx_out_data !== 8'hc3 ||
           dut.tx_count !== 5'd2 || txd !== 1'b0)
            $fatal(1,"FAIL RESET_PRECONDITION");
        resetn=0;
        repeat(3) @(negedge clk);
        if(rx_out_valid !== 1'b0 || tx_in_ready !== 1'b0 ||
           txd !== 1'b1 || fe !== 1'b0 || ov !== 1'b0)
            $fatal(1,"FAIL RESET_FLUSH");
        resetn=1;
        @(negedge clk);
        if(tx_in_ready !== 1'b1 || rx_out_valid !== 1'b0)
            $fatal(1,"FAIL RESET_RELEASE");
        repeat(CPB*20) begin
            @(negedge clk);
            if(txd !== 1'b1 || rx_out_valid !== 1'b0 ||
               tx_in_ready !== 1'b1)
                $fatal(1,"FAIL RESET_STALE_DATA");
        end
        $display("T4_RESET_PASS");
        if(accepted!=18 || received!=18 || rx_checked!=17)
            $fatal(1,"FAIL FINAL_COUNTS");
        $display("PASS CH14 tx=18 rx=16+17 overrun=1 reset=1");
        $finish;
    end
endmodule
