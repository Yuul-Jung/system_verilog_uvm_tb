`timescale 1ns/1ps
// CH21: UVM RAL frontdoor + adapter + predictor. DUT is read-only.
interface axi21_if(input logic clk);
    logic resetn=0;
    logic [31:0] awaddr=0,wdata=0,araddr=0;
    logic [3:0] wstrb=0;
    logic awvalid=0,wvalid=0,bready=0,arvalid=0,rready=0;
    wire awready,wready,bvalid,arready,rvalid;
    wire [1:0] bresp,rresp;
    wire [31:0] rdata;
endinterface

package ch21_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // AXI4-Lite master transaction: one completed read or write.
    class axi21_item extends uvm_sequence_item;
        `uvm_object_utils(axi21_item)
        bit is_write;
        bit [31:0] addr,data;
        bit [3:0] strb=4'hf;
        bit [1:0] resp;
        function new(string name="axi21_item");
            super.new(name);
        endfunction
    endclass

    class axi21_adapter extends uvm_reg_adapter;
        `uvm_object_utils(axi21_adapter)
        function new(string name="axi21_adapter");
            super.new(name);
            // (변경) 전체 레지스터 접근만 수행한다. 개별 필드 byte 접근은 미지원.
            supports_byte_enable=0;
            provides_responses=0;
        endfunction
        virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
            axi21_item t=axi21_item::type_id::create("t");
            t.is_write=(rw.kind==UVM_WRITE);
            t.addr=rw.addr;
            t.data=rw.data;
            t.strb=rw.byte_en;
            return t;
        endfunction
        virtual function void bus2reg(uvm_sequence_item bus_item,
                                       ref uvm_reg_bus_op rw);
            axi21_item t;
            if (!$cast(t,bus_item))
                `uvm_fatal("ADAPTER","Unexpected bus transaction")
            rw.kind=t.is_write ? UVM_WRITE : UVM_READ;
            rw.addr=t.addr;
            rw.data=t.data;
            rw.byte_en=t.strb;
            rw.status=(t.resp==2'b00) ? UVM_IS_OK : UVM_NOT_OK;
        endfunction
    endclass

    class axi21_reg extends uvm_reg;
        `uvm_object_utils(axi21_reg)
        uvm_reg_field value;
        string access_mode="RW";
        bit is_control=0;
        uvm_reg_field mode, reserved;
        uvm_reg_data_t reset_value=0;
        function new(string name="axi21_reg");
            super.new(name,32,UVM_NO_COVERAGE);
        endfunction
        virtual function void build();
            value=uvm_reg_field::type_id::create("value");
            // (변경) CONTROL의 실제 쓰기 가능 범위는 3비트뿐이다.
            if (is_control) begin
                value.configure(this,1,0,"RW",0,0,1,0,0); // enable
                mode=uvm_reg_field::type_id::create("mode");
                mode.configure(this,2,1,"RW",0,0,1,0,0);
                reserved=uvm_reg_field::type_id::create("reserved");
                reserved.configure(this,29,3,"RO",0,0,1,0,0);
            end else
                value.configure(this,32,0,access_mode,0,reset_value,1,0,0);
        endfunction
    endclass

    class axi21_block extends uvm_reg_block;
        `uvm_object_utils(axi21_block)
        axi21_reg control,data_in,version_reg,id_reg;
        function new(string name="axi21_block");
            super.new(name,UVM_NO_COVERAGE);
        endfunction
        virtual function void build();
            default_map=create_map("map",0,4,UVM_LITTLE_ENDIAN,1);
            control=axi21_reg::type_id::create("control");
            control.is_control=1;
            control.configure(this);
            control.build();
            default_map.add_reg(control,'h00,"RW");
            data_in=axi21_reg::type_id::create("data_in");
            data_in.configure(this);
            data_in.build();
            default_map.add_reg(data_in,'h10,"RW");
            version_reg=axi21_reg::type_id::create("version_reg");
            version_reg.access_mode="RO";
            version_reg.reset_value=32'h00010000;
            version_reg.configure(this);
            version_reg.build();
            default_map.add_reg(version_reg,'h18,"RO");
            id_reg=axi21_reg::type_id::create("id_reg");
            id_reg.access_mode="RO";
            id_reg.reset_value=32'h524D4150;
            id_reg.configure(this);
            id_reg.build();
            default_map.add_reg(id_reg,'h1c,"RO");
            lock_model();
        endfunction
    endclass

    class axi21_sequencer extends uvm_sequencer #(axi21_item);
        `uvm_component_utils(axi21_sequencer)
        function new(string name,uvm_component parent);
            super.new(name,parent);
        endfunction
    endclass

    class axi21_driver extends uvm_driver #(axi21_item);
        `uvm_component_utils(axi21_driver)
        virtual axi21_if vif;
        function new(string name,uvm_component parent);
            super.new(name,parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual axi21_if)::get(this,"","vif",vif))
                `uvm_fatal("NO_VIF","Missing AXI interface")
        endfunction
        task automatic write_one(axi21_item t);
            // AW and W independent; hold both until their handshakes.
            bit aw_done=0,w_done=0;
            @(negedge vif.clk);
            vif.awaddr=t.addr;vif.wdata=t.data;vif.wstrb=t.strb;
            vif.awvalid=1;vif.wvalid=1;
            for(int k=0;k<100;k++) begin
                @(posedge vif.clk);
                if(vif.awvalid && vif.awready) aw_done=1;
                if(vif.wvalid && vif.wready) w_done=1;
                @(negedge vif.clk);
                if(aw_done) vif.awvalid=0;
                if(w_done) vif.wvalid=0;
                if(aw_done && w_done) break;
            end
            if(!aw_done || !w_done) `uvm_fatal("AW_W","Handshake timeout")
            for(int k=0;k<100;k++) begin
                @(negedge vif.clk);
                if(vif.bvalid) begin
                    t.resp=vif.bresp;
                    vif.bready=1;
                    @(posedge vif.clk);
                    if (vif.bvalid !== 1'b1 || vif.bresp !== t.resp)
                        `uvm_fatal("B_HANDSHAKE","Response changed before acceptance")
                    @(negedge vif.clk);
                    vif.bready=0;
                    return;
                end
            end
            `uvm_fatal("B_TIMEOUT","Write response timeout")
        endtask
        task automatic read_one(axi21_item t);
            bit accepted=0;
            @(negedge vif.clk);
            vif.araddr=t.addr;vif.arvalid=1;
            for(int k=0;k<100;k++) begin
                @(posedge vif.clk);
                if(vif.arvalid && vif.arready) accepted=1;
                @(negedge vif.clk);
                if(accepted) begin vif.arvalid=0;break;end
            end
            if(!accepted) `uvm_fatal("AR_TIMEOUT","Address timeout")
            for(int k=0;k<100;k++) begin
                @(negedge vif.clk);
                if(vif.rvalid) begin
                    t.data=vif.rdata;t.resp=vif.rresp;
                    vif.rready=1;
                    @(posedge vif.clk);
                    if (vif.rvalid !== 1'b1 || vif.rresp !== t.resp ||
                        vif.rdata !== t.data)
                        `uvm_fatal("R_HANDSHAKE","Response changed before acceptance")
                    @(negedge vif.clk);
                    vif.rready=0;
                    return;
                end
            end
            `uvm_fatal("R_TIMEOUT","Read response timeout")
        endtask
        task run_phase(uvm_phase phase);
            axi21_item req;
            forever begin
                seq_item_port.get_next_item(req);
                if(req.is_write) write_one(req);
                else read_one(req);
                seq_item_port.item_done();
            end
        endtask
    endclass

    // (추가) 실제 공개 버스 상승 에지에서만 완료 거래를 재구성한다.
    // Driver의 요청 객체를 Predictor로 전달하지 않는다.
    class axi21_monitor extends uvm_monitor;
        `uvm_component_utils(axi21_monitor)
        virtual axi21_if vif;
        uvm_analysis_port #(axi21_item) ap;
        bit have_aw=0, have_w=0, have_ar=0;
        logic [31:0] wa, wd, ra;
        logic [3:0] ws;
        int unsigned writes=0, reads=0;
        axi21_item last_write, last_read;
        function new(string name,uvm_component parent);
            super.new(name,parent);
            ap=new("ap",this);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if(!uvm_config_db#(virtual axi21_if)::get(this,"","vif",vif))
                `uvm_fatal("NO_VIF","Monitor interface missing")
        endfunction
        task run_phase(uvm_phase phase);
            axi21_item t;
            forever begin
                @(posedge vif.clk);
                if(vif.resetn === 1'b0) begin
                    have_aw=0; have_w=0; have_ar=0;
                end else begin
                    if ((^{vif.resetn,vif.awvalid,vif.awready,
                           vif.wvalid,vif.wready,vif.bvalid,vif.bready,
                           vif.arvalid,vif.arready,vif.rvalid,vif.rready}) === 1'bx)
                        `uvm_fatal("BUS_X","Unknown handshake signal")
                    if(vif.awvalid && vif.awready) begin
                        if(have_aw || (^vif.awaddr) === 1'bx)
                            `uvm_fatal("MON_AW","Duplicate or unknown AW")
                        wa=vif.awaddr; have_aw=1;
                    end
                    if(vif.wvalid && vif.wready) begin
                        if(have_w || (^{vif.wdata,vif.wstrb}) === 1'bx)
                            `uvm_fatal("MON_W","Duplicate or unknown W")
                        wd=vif.wdata; ws=vif.wstrb; have_w=1;
                    end
                    if(vif.bvalid && vif.bready) begin
                        if(!have_aw || !have_w || vif.bresp !== 2'b00)
                            `uvm_fatal("MON_B","Unexpected write response")
                        t=axi21_item::type_id::create("observed_write");
                        t.is_write=1; t.addr=wa; t.data=wd; t.strb=ws;
                        t.resp=vif.bresp;
                        have_aw=0; have_w=0;
                        writes++; last_write=t; ap.write(t);
                    end
                    if(vif.arvalid && vif.arready) begin
                        if(have_ar || (^vif.araddr) === 1'bx)
                            `uvm_fatal("MON_AR","Duplicate or unknown AR")
                        ra=vif.araddr; have_ar=1;
                    end
                    if(vif.rvalid && vif.rready) begin
                        if(!have_ar || vif.rresp !== 2'b00 ||
                           (^vif.rdata) === 1'bx)
                            `uvm_fatal("MON_R","Unexpected read response")
                        t=axi21_item::type_id::create("observed_read");
                        t.is_write=0; t.addr=ra; t.data=vif.rdata;
                        t.strb=4'hf; t.resp=vif.rresp;
                        have_ar=0;
                        reads++; last_read=t; ap.write(t);
                    end
                end
            end
        endtask
    endclass

    class axi21_env extends uvm_env;
        `uvm_component_utils(axi21_env)
        axi21_driver drv;
        axi21_monitor mon;
        axi21_sequencer sqr;
        axi21_adapter adapter;
        axi21_block model;
        uvm_reg_predictor #(axi21_item) predictor;
        function new(string name,uvm_component parent);
            super.new(name,parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            drv=axi21_driver::type_id::create("drv",this);
            mon=axi21_monitor::type_id::create("mon",this);
            sqr=axi21_sequencer::type_id::create("sqr",this);
            predictor=uvm_reg_predictor#(axi21_item)::type_id::create("predictor",this);
            adapter=axi21_adapter::type_id::create("adapter");
            model=axi21_block::type_id::create("model");
            model.build();
        endfunction
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            drv.seq_item_port.connect(sqr.seq_item_export);
            model.default_map.set_sequencer(sqr,adapter);
            model.default_map.set_auto_predict(0);
            predictor.map=model.default_map;
            predictor.adapter=adapter;
            // (변경) 부정 시험에서는 명시적 예측 경로만 끊는다.
            if (!$test$plusargs("NO_PREDICT"))
                mon.ap.connect(predictor.bus_in);
        endfunction
    endclass

    class axi21_test extends uvm_test;
        `uvm_component_utils(axi21_test)
        axi21_env env;
        virtual axi21_if vif;
        int unsigned read_checks=0, write_checks=0;
        bit done=0;
        function new(string name,uvm_component parent);
            super.new(name,parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env=axi21_env::type_id::create("env",this);
            if(!uvm_config_db#(virtual axi21_if)::get(this,"","vif",vif))
                `uvm_fatal("NO_VIF","Test interface missing")
        endfunction
        // (추가) RAL 반환과 실제 버스 거래를 함께 확인한다.
        task automatic write_expect(uvm_reg rg, bit [31:0] addr,
                                    bit [31:0] data, bit [31:0] expected);
            uvm_status_e status;
            rg.write(status,data,UVM_FRONTDOOR,env.model.default_map);
            write_checks++;
            if(status!=UVM_IS_OK || env.mon.writes!=write_checks ||
               env.mon.last_write==null ||
               env.mon.last_write.addr!==addr ||
               env.mon.last_write.data!==data ||
               env.mon.last_write.strb!==4'hf)
                `uvm_fatal("WRITE","Write status or observed transaction mismatch")
            // 읽기 전에 확인해야 read prediction이 쓰기 예측 누락을 가리지 않는다.
            if(rg.get_mirrored_value() !== uvm_reg_data_t'(expected))
                `uvm_fatal("PREDICT_WRITE",$sformatf(
                    "addr=%h expected=%h",addr,expected))
        endtask

        task automatic read_expect(uvm_reg rg, bit [31:0] addr,
                                   bit [31:0] expected);
            uvm_status_e status;
            uvm_reg_data_t value;
            rg.read(status,value,UVM_FRONTDOOR,env.model.default_map);
            read_checks++;
            if(status!=UVM_IS_OK || value!==uvm_reg_data_t'(expected) ||
               env.mon.reads!=read_checks || env.mon.last_read==null ||
               env.mon.last_read.addr!==addr ||
               env.mon.last_read.data!==expected ||
               rg.get_mirrored_value()!==uvm_reg_data_t'(expected))
                `uvm_fatal("READ",$sformatf("Read mismatch addr=%h",addr))
        endtask

        task run_phase(uvm_phase phase);
            phase.raise_objection(this);
            repeat(4) @(negedge vif.clk);
            vif.resetn=1;
            @(negedge vif.clk);
            env.model.reset(); // 모델만 초기화한다. DUT reset은 위에서 수행.

            read_expect(env.model.control,32'h00,32'h0);
            read_expect(env.model.data_in,32'h10,32'h0);
            write_expect(env.model.data_in,32'h10,32'h11223344,32'h11223344);
            read_expect(env.model.data_in,32'h10,32'h11223344);
            // (추가) 예약 비트는 1을 써도 읽기값과 mirror가 0이어야 한다.
            write_expect(env.model.control,32'h00,32'hFFFFFFFF,32'h7);
            read_expect(env.model.control,32'h00,32'h7);
            write_expect(env.model.control,32'h00,32'h5,32'h5);
            read_expect(env.model.control,32'h00,32'h5);
            read_expect(env.model.version_reg,32'h18,32'h00010000);
            read_expect(env.model.id_reg,32'h1C,32'h524D4150);
            done=1;
            phase.drop_objection(this);
        endtask
        function void check_phase(uvm_phase phase);
            super.check_phase(phase);
            if(!done || read_checks!=7 || write_checks!=3 ||
               env.mon.reads!=7 || env.mon.writes!=3 ||
               env.mon.have_aw || env.mon.have_w || env.mon.have_ar)
                `uvm_fatal("COUNTS","Incomplete RAL verification")
        endfunction
        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            if (uvm_report_server::get_server().get_severity_count(UVM_ERROR)!=0 ||
                uvm_report_server::get_server().get_severity_count(UVM_FATAL)!=0)
                `uvm_fatal("REPORT","UVM error or fatal reported")
            `uvm_info("RESULT","PASS CH21 RAL reads=7 writes=3",UVM_NONE)
        endfunction
    endclass
endpackage

module tb_axi_uvm_ral;
    import uvm_pkg::*;
    import ch21_pkg::*;
    logic clk=0;
    always #5 clk=~clk;
    axi21_if bus(clk);
    wire wr_en;
    wire [7:0] wr_offset,rd_offset;
    wire [31:0] wr_data,rd_data;
    wire [3:0] wr_strb;
    wire enable_o,start_pulse_o,clear_pulse_o;
    wire [1:0] mode_o,irq_status_o;
    wire [31:0] data_in_o;
    axi4lite_slave_adapter dut(
        .s_axi_aclk(clk),.s_axi_aresetn(bus.resetn),
        .s_axi_awaddr(bus.awaddr),.s_axi_awprot(3'b000),
        .s_axi_awvalid(bus.awvalid),.s_axi_awready(bus.awready),
        .s_axi_wdata(bus.wdata),.s_axi_wstrb(bus.wstrb),
        .s_axi_wvalid(bus.wvalid),.s_axi_wready(bus.wready),
        .s_axi_bresp(bus.bresp),.s_axi_bvalid(bus.bvalid),.s_axi_bready(bus.bready),
        .s_axi_araddr(bus.araddr),.s_axi_arprot(3'b000),
        .s_axi_arvalid(bus.arvalid),.s_axi_arready(bus.arready),
        .s_axi_rdata(bus.rdata),.s_axi_rresp(bus.rresp),
        .s_axi_rvalid(bus.rvalid),.s_axi_rready(bus.rready),
        .wr_en(wr_en),.wr_offset(wr_offset),.wr_data(wr_data),
        .wr_strb(wr_strb),.rd_offset(rd_offset),.rd_data(rd_data)
    );
    custom_register_bank bank(
        .clk(clk),.resetn(bus.resetn),.wr_en(wr_en),
        .wr_offset(wr_offset),.wr_data(wr_data),.wr_strb(wr_strb),
        .rd_offset(rd_offset),.rd_data(rd_data),
        .busy_i(1'b0),.done_i(1'b0),.error_i(1'b0),
        .irq_done_event_i(1'b0),.irq_error_event_i(1'b0),
        .data_out_i(32'h12345678),.enable_o(enable_o),
        .mode_o(mode_o),.start_pulse_o(start_pulse_o),
        .clear_pulse_o(clear_pulse_o),.data_in_o(data_in_o),
        .irq_status_o(irq_status_o)
    );
    initial begin
        // (변경) test 자체도 정확한 경로로 설정한다.
        uvm_config_db#(virtual axi21_if)::set(null,"uvm_test_top","vif",bus);
        uvm_config_db#(virtual axi21_if)::set(null,"uvm_test_top.env.drv","vif",bus);
        uvm_config_db#(virtual axi21_if)::set(null,"uvm_test_top.env.mon","vif",bus);
        run_test("axi21_test");
    end
    initial begin
        #100000;
        $fatal(1,"CH21 GLOBAL_TIMEOUT");
    end
endmodule
