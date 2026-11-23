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
            supports_byte_enable=1;
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
        uvm_reg_data_t reset_value=0;
        function new(string name="axi21_reg");
            super.new(name,32,UVM_NO_COVERAGE);
        endfunction
        virtual function void build();
            value=uvm_reg_field::type_id::create("value");
            value.configure(this,32,0,access_mode,0,reset_value,1,1,0);
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
        uvm_analysis_port #(axi21_item) completed_ap;
        function new(string name,uvm_component parent);
            super.new(name,parent);
            completed_ap=new("completed_ap",this);
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
                // Completion stream feeds predictor; it is NOT an independent bus monitor.
                completed_ap.write(req);
                seq_item_port.item_done();
            end
        endtask
    endclass

    class axi21_env extends uvm_env;
        `uvm_component_utils(axi21_env)
        axi21_driver drv;
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
            drv.completed_ap.connect(predictor.bus_in);
        endfunction
    endclass

    class axi21_test extends uvm_test;
        `uvm_component_utils(axi21_test)
        axi21_env env;
        virtual axi21_if vif;
        function new(string name,uvm_component parent);
            super.new(name,parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env=axi21_env::type_id::create("env",this);
            if(!uvm_config_db#(virtual axi21_if)::get(this,"","vif",vif))
                `uvm_fatal("NO_VIF","Test interface missing")
        endfunction
        task run_phase(uvm_phase phase);
            uvm_status_e status;
            uvm_reg_data_t value;
            phase.raise_objection(this);
            repeat(4) @(negedge vif.clk);
            vif.resetn=1;
            @(negedge vif.clk);
            env.model.reset();

            // Frontdoor: RAL -> adapter -> AXI driver -> DUT.
            env.model.data_in.write(status,32'h11223344);
            if(status!=UVM_IS_OK) `uvm_fatal("WRITE","DATA_IN write failed")
            env.model.data_in.read(status,value);
            if(status!=UVM_IS_OK || value!==32'h11223344)
                `uvm_fatal("DATA_IN","Readback mismatch")
            if(env.model.data_in.get_mirrored_value()!==32'h11223344)
                `uvm_fatal("PREDICT","Mirror did not update")

            env.model.control.write(status,32'h00000005);
            env.model.control.read(status,value);
            if(status!=UVM_IS_OK || value!==32'h00000005)
                `uvm_fatal("CONTROL","Readback mismatch")
            env.model.version_reg.read(status,value);
            if(status!=UVM_IS_OK || value!==32'h00010000)
                `uvm_fatal("VERSION","VERSION mismatch")
            env.model.id_reg.read(status,value);
            if(status!=UVM_IS_OK || value!==32'h524D4150)
                `uvm_fatal("ID","ID mismatch")
            `uvm_info("CH21","PASS CH21 RAL frontdoor reads=4 writes=2",UVM_LOW)
            phase.drop_objection(this);
        endtask
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
        uvm_config_db#(virtual axi21_if)::set(null,"uvm_test_top.*","vif",bus);
        run_test("axi21_test");
    end
    initial begin
        #100000;
        $fatal(1,"CH21 GLOBAL_TIMEOUT");
    end
endmodule
