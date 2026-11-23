`timescale 1ns/1ps
// 제15장: 기존 AXI4-Lite 어댑터 + 레지스터 뱅크를 읽기 전용 DUT로 검증.
// AW/W 독립 수락, B/R 대기 유지, WSTRB 부분 쓰기, Reset을 자동 판정한다.
module tb_axi4lite_registers;
    reg clk=0, resetn=0;
    always #5 clk=~clk;
    reg [31:0] awaddr=0, wdata=0, araddr=0;
    reg [3:0] wstrb=0;
    reg awvalid=0, wvalid=0, bready=0, arvalid=0, rready=0;
    wire awready,wready,bvalid,arready,rvalid;
    wire [1:0] bresp,rresp;
    wire [31:0] rdata;
    wire wr_en;
    wire [7:0] wr_offset,rd_offset;
    wire [31:0] wr_data,rd_data;
    wire [3:0] wr_strb;
    wire enable_o,start_pulse_o,clear_pulse_o;
    wire [1:0] mode_o,irq_status_o;
    wire [31:0] data_in_o;
    integer checks=0, commits=0;
    reg [31:0] captured;

    axi4lite_slave_adapter dut (
        .s_axi_aclk(clk), .s_axi_aresetn(resetn),
        .s_axi_awaddr(awaddr), .s_axi_awprot(3'b0),
        .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_wdata(wdata), .s_axi_wstrb(wstrb),
        .s_axi_wvalid(wvalid), .s_axi_wready(wready),
        .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(bready),
        .s_axi_araddr(araddr), .s_axi_arprot(3'b0),
        .s_axi_arvalid(arvalid), .s_axi_arready(arready),
        .s_axi_rdata(rdata), .s_axi_rresp(rresp),
        .s_axi_rvalid(rvalid), .s_axi_rready(rready),
        .wr_en(wr_en), .wr_offset(wr_offset), .wr_data(wr_data),
        .wr_strb(wr_strb), .rd_offset(rd_offset), .rd_data(rd_data)
    );
    custom_register_bank bank (
        .clk(clk), .resetn(resetn), .wr_en(wr_en),
        .wr_offset(wr_offset), .wr_data(wr_data), .wr_strb(wr_strb),
        .rd_offset(rd_offset), .rd_data(rd_data),
        .busy_i(1'b0), .done_i(1'b0), .error_i(1'b0),
        .irq_done_event_i(1'b0), .irq_error_event_i(1'b0),
        .data_out_i(32'h12345678), .enable_o(enable_o),
        .mode_o(mode_o), .start_pulse_o(start_pulse_o),
        .clear_pulse_o(clear_pulse_o), .data_in_o(data_in_o),
        .irq_status_o(irq_status_o)
    );
    // 두 채널을 모두 수락한 다음에만 wr_en이 1회 발생해야 한다.
    always @(posedge clk) if(resetn && wr_en) commits=commits+1;

    task automatic send_aw(input [31:0] address);
        integer guard;
        begin
            @(negedge clk);
            awaddr=address; awvalid=1;
            guard=0;
            while(awready !== 1'b1) begin
                @(negedge clk);
                guard=guard+1;
                if(guard>100) $fatal(1,"FAIL AW_TIMEOUT");
            end
            @(posedge clk);
            @(negedge clk);
            awvalid=0;
        end
    endtask

    task automatic send_w(input [31:0] data,input [3:0] strobe);
        integer guard;
        begin
            @(negedge clk);
            wdata=data; wstrb=strobe; wvalid=1;
            guard=0;
            while(wready !== 1'b1) begin
                @(negedge clk);
                guard=guard+1;
                if(guard>100) $fatal(1,"FAIL W_TIMEOUT");
            end
            @(posedge clk);
            @(negedge clk);
            wvalid=0;
        end
    endtask

    task automatic finish_b;
        integer guard;
        begin
            guard=0;
            while(bvalid !== 1'b1) begin
                @(negedge clk);
                guard=guard+1;
                if(guard>100) $fatal(1,"FAIL B_TIMEOUT");
            end
            if(bresp !== 2'b00) $fatal(1,"FAIL BRESP");
            // 응답을 받지 않는 동안 BVALID는 내려가면 안 된다.
            repeat(3) begin
                @(negedge clk);
                if(bvalid !== 1'b1 || awready !== 1'b0 ||
                   wready !== 1'b0) $fatal(1,"FAIL B_HOLD");
            end
            bready=1;
            @(posedge clk);
            @(negedge clk);
            bready=0;
            if(bvalid !== 1'b0) $fatal(1,"FAIL B_CLEAR");
            checks=checks+1;
        end
    endtask

    task automatic read_expect(input [31:0] address,input [31:0] expected);
        integer guard;
        begin
            @(negedge clk);
            araddr=address; arvalid=1;
            guard=0;
            while(arready !== 1'b1) begin
                @(negedge clk);
                guard=guard+1;
                if(guard>100) $fatal(1,"FAIL AR_TIMEOUT");
            end
            @(posedge clk);
            @(negedge clk);
            arvalid=0;
            if(rvalid !== 1'b1 || rresp !== 2'b00 || rdata !== expected)
                $fatal(1,"FAIL READ addr=%h got=%h exp=%h",address,rdata,expected);
            captured=rdata;
            repeat(3) begin
                @(negedge clk);
                if(rvalid !== 1'b1 || arready !== 1'b0 ||
                   rdata !== captured) $fatal(1,"FAIL R_HOLD");
            end
            rready=1;
            @(posedge clk);
            @(negedge clk);
            rready=0;
            if(rvalid !== 1'b0) $fatal(1,"FAIL R_CLEAR");
            checks=checks+1;
        end
    endtask

    initial begin
        #20000;
        $fatal(1,"FAIL GLOBAL_TIMEOUT");
    end

    initial begin
        $dumpfile("ch15_axi4lite.vcd");
        $dumpvars(0,tb_axi4lite_registers);
        repeat(4) @(negedge clk);
        if(awready !== 1'b0 || wready !== 1'b0 ||
           arready !== 1'b0) $fatal(1,"FAIL RESET_READY");
        resetn=1;
        @(negedge clk);

        // T1: AW를 먼저 보내고 W가 오기 전에는 commit하지 않는다.
        send_aw(32'h10);
        repeat(3) @(negedge clk);
        if(commits!=0 || bvalid !== 1'b0) $fatal(1,"FAIL AW_ONLY");
        send_w(32'h11223344,4'b1111);
        finish_b();
        read_expect(32'h10,32'h11223344);
        $display("T1_AW_BEFORE_W_PASS");

        // T2: W를 먼저 보내도 독립 버퍼에 보관된다.
        send_w(32'hAABBCCDD,4'b0101);
        repeat(3) @(negedge clk);
        if(commits!=1 || bvalid !== 1'b0) $fatal(1,"FAIL W_ONLY");
        send_aw(32'h10);
        finish_b();
        read_expect(32'h10,32'h11BB33DD);
        $display("T2_W_BEFORE_AW_WSTRB_PASS");

        // T3: CONTROL, VERSION, ID 및 읽기 응답 유지.
        send_aw(32'h00);
        send_w(32'h00000005,4'b0001);
        finish_b();
        read_expect(32'h00,32'h00000005);
        read_expect(32'h18,32'h00010000);
        read_expect(32'h1C,32'h524D4150);
        if(enable_o !== 1'b1 || mode_o !== 2'b10)
            $fatal(1,"FAIL CONTROL_OUTPUT");
        $display("T3_CONTROL_RO_PASS");

        // T4: 리셋 후 CONTROL/DATA_IN 초기화, 채널 준비 복구.
        @(negedge clk);
        resetn=0;
        repeat(3) @(negedge clk);
        if(bvalid !== 1'b0 || rvalid !== 1'b0 ||
           enable_o !== 1'b0 || data_in_o !== 32'b0)
            $fatal(1,"FAIL RESET_CLEAR");
        resetn=1;
        @(negedge clk);
        read_expect(32'h10,32'h00000000);
        read_expect(32'h00,32'h00000000);
        if(commits!=3 || checks!=9)
            $fatal(1,"FAIL COUNTS commits=%0d checks=%0d",commits,checks);
        $display("T4_RESET_PASS");
        $display("PASS CH15 commits=%0d checks=%0d",commits,checks);
        $finish;
    end
endmodule
