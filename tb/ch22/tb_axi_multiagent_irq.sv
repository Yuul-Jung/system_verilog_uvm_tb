`timescale 1ns/1ps
// 제22장: AXI4-Lite Master Agent + Reset/IRQ Agent + Virtual Sequence.
// 상용 AMD AXI VIP가 아닌 교육용 VIP-style(재사용 검증 컴포넌트) 구현.
// 기존 axi4lite_slave_adapter.v 및 custom_register_bank.v는 수정하지 않는다.

// (추가) 버스 전용 Interface: AXI 신호만 묶는다.
interface axi22_if(input logic clk, input logic resetn);
    logic [31:0] awaddr=0, wdata=0, araddr=0;
    logic [3:0] wstrb=0;
    logic awvalid=0, wvalid=0, bready=0, arvalid=0, rready=0;
    wire awready, wready, bvalid, arready, rvalid;
    wire [1:0] bresp, rresp;
    wire [31:0] rdata;
endinterface

// (추가) 하드웨어 이벤트 전용 Interface: AXI와 구동 책임을 분리한다.
interface irq22_if(input logic clk);
    logic resetn=0;
    logic done_event=0, error_event=0;
    wire [1:0] irq_status;
    // (추가) 공개 레지스터 뱅크 입력: 실제 commit 경계 관찰 및 충돌 자극.
    wire wr_en;
    wire [7:0] wr_offset;
    wire [31:0] wr_data;
    wire [3:0] wr_strb;
endinterface

package ch22_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // 두 개의 독립 Analysis Imp(write_bus/write_irq)를 선언한다.
    `uvm_analysis_imp_decl(_bus)
    `uvm_analysis_imp_decl(_irq)

    typedef enum {EV_RELEASE, EV_ASSERT_RESET, EV_DONE, EV_ERROR, EV_BOTH_ON_CLEAR} evt22_kind_e;

    class axi22_item extends uvm_sequence_item;
        `uvm_object_utils(axi22_item)
        bit is_write;
        bit [31:0] addr, data;
        bit [3:0] strb=4'hf;
        bit [1:0] resp=0;
        time ar_stamp;
        function new(string name="axi22_item");
            super.new(name);
        endfunction
    endclass

    class irq22_item extends uvm_sequence_item;
        `uvm_object_utils(irq22_item)
        evt22_kind_e kind;
        function new(string name="irq22_item");
            super.new(name);
        endfunction
    endclass

    class irq22_sample extends uvm_sequence_item;
        `uvm_object_utils(irq22_sample)
        logic resetn, done_event, error_event, wr_en;
        logic [7:0] offset;
        logic [31:0] data;
        logic [3:0] strb;
        logic [1:0] status;
        time stamp;
        function new(string name="irq22_sample");
            super.new(name);
        endfunction
    endclass

    class axi22_sequencer extends uvm_sequencer #(axi22_item);
        `uvm_component_utils(axi22_sequencer)
        function new(string name, uvm_component parent);
            super.new(name,parent);
        endfunction
    endclass

    class irq22_sequencer extends uvm_sequencer #(irq22_item);
        `uvm_component_utils(irq22_sequencer)
        function new(string name, uvm_component parent);
            super.new(name,parent);
        endfunction
    endclass

    // AXI Master Driver: AW/W 독립 Handshake와 B/R Backpressure를 보존한다.
    class axi22_driver extends uvm_driver #(axi22_item);
        `uvm_component_utils(axi22_driver)
        virtual axi22_if vif;
        int unsigned driven=0;
        function new(string name,uvm_component parent);
            super.new(name,parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual axi22_if)::get(this,"","vif",vif))
                `uvm_fatal("AXI_VIF","AXI interface missing")
        endfunction
        task automatic write_one(axi22_item t);
            bit aw_done=0, w_done=0;
            @(negedge vif.clk);
            vif.awaddr=t.addr; vif.awvalid=1'b1;
            vif.wdata=t.data; vif.wstrb=t.strb; vif.wvalid=1'b1;
            for (int k=0;k<100;k++) begin
                @(posedge vif.clk);
                if (vif.awvalid && vif.awready) aw_done=1;
                if (vif.wvalid && vif.wready) w_done=1;
                @(negedge vif.clk);
                if (aw_done) vif.awvalid=1'b0;
                if (w_done) vif.wvalid=1'b0;
                if (aw_done && w_done) break;
            end
            if (!aw_done || !w_done)
                `uvm_fatal("AXI_AW_W","Write handshake timeout")
            for (int k=0;k<100;k++) begin
                @(negedge vif.clk);
                if (vif.bvalid) begin
                    t.resp=vif.bresp;
                    // 두 클록 동안 BREADY=0 → 응답 유지 후 수락.
                    repeat (2) begin
                        @(negedge vif.clk);
                        if (vif.bvalid !== 1'b1 || vif.bresp !== t.resp)
                            `uvm_fatal("B_HOLD","Write response changed during stall")
                    end
                    vif.bready=1'b1;
                    @(posedge vif.clk);
                    @(negedge vif.clk);
                    vif.bready=1'b0;
                    return;
                end
            end
            `uvm_fatal("B_TIMEOUT","Write response timeout")
        endtask
        task automatic read_one(axi22_item t);
            bit ar_done=0;
            @(negedge vif.clk);
            vif.araddr=t.addr; vif.arvalid=1'b1;
            for (int k=0;k<100;k++) begin
                @(posedge vif.clk);
                if (vif.arvalid && vif.arready) ar_done=1;
                @(negedge vif.clk);
                if (ar_done) begin vif.arvalid=1'b0; break; end
            end
            if (!ar_done) `uvm_fatal("AR_TIMEOUT","Read address timeout")
            for (int k=0;k<100;k++) begin
                @(negedge vif.clk);
                if (vif.rvalid) begin
                    t.data=vif.rdata; t.resp=vif.rresp;
                    // 두 클록 동안 RREADY=0 → 데이터 유지 검사.
                    repeat (2) begin
                        @(negedge vif.clk);
                        if (vif.rvalid !== 1'b1 || vif.rdata !== t.data ||
                            vif.rresp !== t.resp)
                            `uvm_fatal("R_HOLD","Read response changed during stall")
                    end
                    vif.rready=1'b1;
                    @(posedge vif.clk);
                    @(negedge vif.clk);
                    vif.rready=1'b0;
                    return;
                end
            end
            `uvm_fatal("R_TIMEOUT","Read response timeout")
        endtask
        task run_phase(uvm_phase phase);
            axi22_item req;
            forever begin
                seq_item_port.get_next_item(req);
                if (req.is_write) write_one(req);
                else read_one(req);
                driven++;
                seq_item_port.item_done();
            end
        endtask
    endclass

    // AXI Monitor는 Driver 완료 이벤트를 쓰지 않고 실제 5채널을 관찰한다.
    class axi22_monitor extends uvm_monitor;
        `uvm_component_utils(axi22_monitor)
        virtual axi22_if vif;
        uvm_analysis_port #(axi22_item) ap;
        bit aw_seen=0, w_seen=0, ar_seen=0;
        bit [31:0] saved_aw, saved_wd, saved_ar;
        bit [3:0] saved_strb;
        time saved_ar_stamp;
        bit b_held=0, r_held=0;
        logic [1:0] held_bresp, held_rresp;
        logic [31:0] held_rdata;
        function new(string name,uvm_component parent);
            super.new(name,parent);
            ap=new("ap",this);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual axi22_if)::get(this,"","vif",vif))
                `uvm_fatal("AXI_VIF","AXI monitor interface missing")
        endfunction
        task run_phase(uvm_phase phase);
            axi22_item s;
            forever begin
                @(posedge vif.clk); // DUT가 Handshake를 읽는 에지에서 관찰
                if (!vif.resetn) begin
                    aw_seen=0; w_seen=0; ar_seen=0;
                    b_held=0; r_held=0;
                end else begin
                    if ((^{vif.resetn,vif.awvalid,vif.awready,vif.wvalid,vif.wready,
                           vif.bvalid,vif.bready,vif.arvalid,vif.arready,
                           vif.rvalid,vif.rready}) === 1'bx)
                        `uvm_fatal("BUS_X","Unknown handshake")
                    // (추가) 모든 상승 에지에서 응답 대기 및 수락 에지까지 유지 검사.
                    if (b_held && (vif.bvalid !== 1'b1 || vif.bresp !== held_bresp))
                        `uvm_fatal("B_HOLD","B changed while pending")
                    if (r_held && (vif.rvalid !== 1'b1 || vif.rresp !== held_rresp ||
                                   vif.rdata !== held_rdata))
                        `uvm_fatal("R_HOLD","R changed while pending")
                    b_held=vif.bvalid && !vif.bready;
                    r_held=vif.rvalid && !vif.rready;
                    if (b_held) held_bresp=vif.bresp;
                    if (r_held) begin held_rresp=vif.rresp; held_rdata=vif.rdata; end
                    if (vif.awvalid && vif.awready) begin
                        if (aw_seen || (^vif.awaddr) === 1'bx)
                            `uvm_fatal("MON_AW","Duplicate or unknown AW")
                        saved_aw=vif.awaddr; aw_seen=1;
                    end
                    if (vif.wvalid && vif.wready) begin
                        if (w_seen || (^{vif.wdata,vif.wstrb}) === 1'bx)
                            `uvm_fatal("MON_W","Duplicate or unknown W")
                        saved_wd=vif.wdata; saved_strb=vif.wstrb; w_seen=1;
                    end
                    if (vif.arvalid && vif.arready) begin
                        if (ar_seen || (^vif.araddr) === 1'bx)
                            `uvm_fatal("MON_AR","Duplicate or unknown AR")
                        saved_ar=vif.araddr; saved_ar_stamp=$time; ar_seen=1;
                    end
                    if (vif.bvalid && vif.bready) begin
                        if (!aw_seen || !w_seen || vif.bresp !== 2'b00)
                            `uvm_fatal("AXI_MON_B","B before AW/W Handshake")
                        s=axi22_item::type_id::create("observed_write");
                        s.is_write=1; s.addr=saved_aw; s.data=saved_wd;
                        s.strb=saved_strb; s.resp=vif.bresp;
                        ap.write(s);
                        aw_seen=0; w_seen=0;
                    end
                    if (vif.rvalid && vif.rready) begin
                        if (!ar_seen || vif.rresp !== 2'b00 || (^vif.rdata) === 1'bx)
                            `uvm_fatal("AXI_MON_R","R before AR Handshake")
                        s=axi22_item::type_id::create("observed_read");
                        s.is_write=0; s.addr=saved_ar; s.data=vif.rdata;
                        s.ar_stamp=saved_ar_stamp;
                        s.resp=vif.rresp;
                        ap.write(s);
                        ar_seen=0;
                    end
                end
            end
        endtask
    endclass

    // 별도 Event Driver는 Reset/IRQ 입력만 구동한다.
    class irq22_driver extends uvm_driver #(irq22_item);
        `uvm_component_utils(irq22_driver)
        virtual irq22_if vif;
        int unsigned events_driven=0;
        function new(string name,uvm_component parent);
            super.new(name,parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual irq22_if)::get(this,"","vif",vif))
                `uvm_fatal("IRQ_VIF","IRQ interface missing")
        endfunction
        task run_phase(uvm_phase phase);
            irq22_item req;
            forever begin
                seq_item_port.get_next_item(req);
                case (req.kind)
                    EV_RELEASE: begin
                        @(negedge vif.clk);
                        vif.resetn=1'b1;
                    end
                    EV_ASSERT_RESET: begin
                        @(negedge vif.clk);
                        vif.resetn=1'b0;
                        repeat (3) @(negedge vif.clk);
                    end
                    EV_DONE: begin
                        @(negedge vif.clk);
                        vif.done_event=1'b1;
                        @(negedge vif.clk);
                        vif.done_event=1'b0;
                    end
                    EV_ERROR: begin
                        @(negedge vif.clk);
                        vif.error_event=1'b1;
                        @(negedge vif.clk);
                        vif.error_event=1'b0;
                    end
                    // (추가) 실제 bank 쓰기 경계에 두 이벤트를 정렬한다.
                    EV_BOTH_ON_CLEAR: begin
                        int guard=0;
                        do begin
                            @(negedge vif.clk);
                            guard++;
                            if (guard>100) `uvm_fatal("COLLISION_TIMEOUT","No W1C commit")
                        end while (!(vif.wr_en === 1'b1 && vif.wr_offset === 8'h0c &&
                                     vif.wr_strb[0] === 1'b1 && vif.wr_data[1:0] === 2'b11));
                        vif.done_event=1'b1; vif.error_event=1'b1;
                        @(negedge vif.clk);
                        vif.done_event=1'b0; vif.error_event=1'b0;
                    end
                endcase
                events_driven++;
                seq_item_port.item_done();
            end
        endtask
    endclass

    // 별도 Event Monitor: IRQ 상태·Reset을 관찰해 Scoreboard에 전달.
    class irq22_monitor extends uvm_monitor;
        `uvm_component_utils(irq22_monitor)
        virtual irq22_if vif;
        uvm_analysis_port #(irq22_sample) ap;
        function new(string name,uvm_component parent);
            super.new(name,parent);
            ap=new("ap",this);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual irq22_if)::get(this,"","vif",vif))
                `uvm_fatal("IRQ_VIF","IRQ monitor interface missing")
        endfunction
        task run_phase(uvm_phase phase);
            irq22_sample s;
            forever begin
                @(posedge vif.clk);
                // (변경) 입력은 상승 에지, 출력은 NBA 이후에 같은 객체로 관찰.
                s=irq22_sample::type_id::create("cycle");
                s.stamp=$time; s.resetn=vif.resetn;
                s.done_event=vif.done_event; s.error_event=vif.error_event;
                s.wr_en=vif.wr_en; s.offset=vif.wr_offset;
                s.data=vif.wr_data; s.strb=vif.wr_strb;
                #1;
                s.status=vif.irq_status;
                if ($test$plusargs("CORRUPT_IRQ") && s.resetn &&
                    s.done_event && s.error_event && s.wr_en)
                    s.status=s.status ^ 2'b01;
                ap.write(s);
            end
        endtask
    endclass

    // 버스 완료 관찰과 IRQ 이벤트 관찰을 별도 Analysis Imp로 수집.
    class axi22_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(axi22_scoreboard)
        uvm_analysis_imp_bus #(axi22_item,axi22_scoreboard) bus_in;
        uvm_analysis_imp_irq #(irq22_sample,axi22_scoreboard) irq_in;
        bit [31:0] expected_control=0, expected_data=0;
        bit [1:0] expected_irq=0;
        int unsigned writes=0, reads=0, events=0, resets=0;
        int unsigned collisions=0, zero_strobes=0, commits=0;
        bit previous_resetn=1;
        bit [1:0] irq_before[time];
        axi22_item committed[$];
        function new(string name,uvm_component parent);
            super.new(name,parent);
            bus_in=new("bus_in",this);
            irq_in=new("irq_in",this);
        endfunction

        function void write_bus(axi22_item s);
            bit [31:0] exp_data;
            axi22_item c;
            if (s.resp !== 2'b00)
                `uvm_fatal("AXI_RESP","Non-OKAY AXI response")
            if (s.is_write) begin
                if (committed.size()==0)
                    `uvm_fatal("COMMIT","B without register-bank commit")
                c=committed.pop_front();
                if (s.addr[7:0] !== c.addr[7:0] || s.data !== c.data ||
                    s.strb !== c.strb)
                    `uvm_fatal("COMMIT","AXI transaction differs from bank input")
                case (s.addr)
                    'h00: if (s.strb[0])
                        expected_control={29'd0,s.data[2:0]};
                    'h10: for (int i=0;i<4;i++)
                        if (s.strb[i])
                            expected_data[i*8 +: 8]=s.data[i*8 +: 8];
                    'h0c: ; // IRQ는 B 응답이 아니라 실제 commit 에지에서 갱신한다.
                    default: `uvm_fatal("AXI_WR_ADDR","Unexpected write address")
                endcase
                writes++;
            end else begin
                case (s.addr)
                    'h00: exp_data=expected_control;
                    'h0c: begin
                        if (!irq_before.exists(s.ar_stamp))
                            `uvm_fatal("AR_TIME","No IRQ state at AR acceptance")
                        exp_data={30'd0,irq_before[s.ar_stamp]};
                    end
                    'h10: exp_data=expected_data;
                    'h18: exp_data=32'h00010000;
                    'h1c: exp_data=32'h524D4150;
                    default: `uvm_fatal("AXI_RD_ADDR","Unexpected read address")
                endcase
                if (s.data !== exp_data)
                    `uvm_fatal("AXI_READ_MISMATCH",
                        $sformatf("addr=%h got=%h expected=%h",
                                  s.addr,s.data,exp_data))
                reads++;
            end
        endfunction

        function void write_irq(irq22_sample s);
            axi22_item c;
            bit [1:0] clear_mask, set_mask;
            irq_before[s.stamp]=expected_irq;
            if (s.resetn === 1'b0) begin
                if (previous_resetn) resets++;
                if (committed.size()!=0)
                    `uvm_fatal("RESET_PENDING","Unexpected pending bank commit")
                expected_irq=0; expected_control=0; expected_data=0;
                previous_resetn=0;
            end else begin
                if ((^{s.resetn,s.done_event,s.error_event,s.wr_en}) === 1'bx)
                    `uvm_fatal("IRQ_X","Unknown bank control")
                previous_resetn=1;
                clear_mask=0; set_mask={s.error_event,s.done_event};
                if (s.wr_en) begin
                    if ((^{s.offset,s.data,s.strb}) === 1'bx)
                        `uvm_fatal("COMMIT_X","Unknown bank write")
                    c=axi22_item::type_id::create("commit");
                    c.addr={24'd0,s.offset}; c.data=s.data; c.strb=s.strb;
                    committed.push_back(c); commits++;
                    if (s.offset==8'h0c) begin
                        if (s.strb[0]) clear_mask=s.data[1:0];
                        else zero_strobes++;
                    end
                end
                if (s.done_event) events++;
                if (s.error_event) events++;
                if (clear_mask==2'b11 && set_mask==2'b11) collisions++;
                // (추가) 동일 비트의 set이 clear보다 우선.
                expected_irq=(expected_irq & ~clear_mask) | set_mask;
            end
            if (s.status !== expected_irq)
                `uvm_fatal("IRQ_MISMATCH",$sformatf(
                    "status=%b expected=%b collisions=%0d",
                    s.status,expected_irq,collisions))
        endfunction
    endclass

    class axi22_bus_agent extends uvm_agent;
        `uvm_component_utils(axi22_bus_agent)
        axi22_sequencer sqr;
        axi22_driver drv;
        axi22_monitor mon;
        function new(string name,uvm_component parent);
            super.new(name,parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            sqr=axi22_sequencer::type_id::create("sqr",this);
            drv=axi22_driver::type_id::create("drv",this);
            mon=axi22_monitor::type_id::create("mon",this);
        endfunction
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            drv.seq_item_port.connect(sqr.seq_item_export);
        endfunction
    endclass

    class irq22_event_agent extends uvm_agent;
        `uvm_component_utils(irq22_event_agent)
        irq22_sequencer sqr;
        irq22_driver drv;
        irq22_monitor mon;
        function new(string name,uvm_component parent);
            super.new(name,parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            sqr=irq22_sequencer::type_id::create("sqr",this);
            drv=irq22_driver::type_id::create("drv",this);
            mon=irq22_monitor::type_id::create("mon",this);
        endfunction
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            drv.seq_item_port.connect(sqr.seq_item_export);
        endfunction
    endclass

    // Virtual Sequencer는 두 Agent의 Sequencer 핸들만 보관한다.
    class axi22_virtual_sequencer extends uvm_sequencer #(uvm_sequence_item);
        `uvm_component_utils(axi22_virtual_sequencer)
        axi22_sequencer bus_sqr;
        irq22_sequencer evt_sqr;
        function new(string name,uvm_component parent);
            super.new(name,parent);
        endfunction
    endclass

    class axi22_bus_sequence extends uvm_sequence #(axi22_item);
        `uvm_object_utils(axi22_bus_sequence)
        bit is_write;
        bit [31:0] addr, send_data;
        bit [3:0] strb=4'hf;
        bit [31:0] return_data;
        bit [1:0] return_resp;
        function new(string name="axi22_bus_sequence");
            super.new(name);
        endfunction
        task body();
            axi22_item req=axi22_item::type_id::create("req");
            start_item(req);
            req.is_write=is_write;
            req.addr=addr; req.data=send_data; req.strb=strb;
            finish_item(req);
            return_data=req.data;
            return_resp=req.resp;
        endtask
    endclass

    class irq22_event_sequence extends uvm_sequence #(irq22_item);
        `uvm_object_utils(irq22_event_sequence)
        evt22_kind_e kind;
        function new(string name="irq22_event_sequence");
            super.new(name);
        endfunction
        task body();
            irq22_item req=irq22_item::type_id::create("req");
            start_item(req);
            req.kind=kind;
            finish_item(req);
        endtask
    endclass

    // Virtual Sequence 하나가 서로 다른 두 Agent를 순서대로 조정한다.
    class axi22_system_sequence extends uvm_sequence #(uvm_sequence_item);
        `uvm_object_utils(axi22_system_sequence)
        `uvm_declare_p_sequencer(axi22_virtual_sequencer)
        function new(string name="axi22_system_sequence");
            super.new(name);
        endfunction

        task automatic ev(evt22_kind_e kind);
            irq22_event_sequence s=irq22_event_sequence::type_id::create("ev");
            s.kind=kind;
            s.start(p_sequencer.evt_sqr);
        endtask

        task automatic wr(bit [31:0] a,bit [31:0] d,bit [3:0] strb=4'hf);
            axi22_bus_sequence s=axi22_bus_sequence::type_id::create("write");
            s.is_write=1; s.addr=a; s.send_data=d; s.strb=strb;
            s.start(p_sequencer.bus_sqr);
            if (s.return_resp !== 2'b00)
                `uvm_fatal("WRITE","Write response was not OKAY")
        endtask

        task automatic rd(bit [31:0] a,bit [31:0] expected);
            axi22_bus_sequence s=axi22_bus_sequence::type_id::create("read");
            s.is_write=0; s.addr=a;
            s.start(p_sequencer.bus_sqr);
            if (s.return_resp !== 2'b00 || s.return_data !== expected)
                `uvm_fatal("READ",
                    $sformatf("addr=%h got=%h expected=%h",
                              a,s.return_data,expected))
        endtask

        task body();
            // 초기 리셋 → 제어/데이터 레지스터 접근.
            ev(EV_RELEASE);
            wr('h00,32'h00000005);
            wr('h10,32'h11223344);
            rd('h00,32'h00000005);
            rd('h10,32'h11223344);

            // 실제 HW IRQ 이벤트 발생 → AXI Read로 관찰.
            ev(EV_DONE);
            rd('h0c,32'h00000001);
            ev(EV_ERROR);
            rd('h0c,32'h00000003);

            // W1C(Write 1 to Clear, 1을 써서 상태 비트 해제) 시험.
            wr('h0c,32'h00000001);
            rd('h0c,32'h00000002);
            wr('h0c,32'h00000002);
            rd('h0c,32'h00000000);

            // (추가) 두 Agent를 동시에 실행하여 같은 commit 에지에서 set/clear 충돌.
            fork
                wr('h0c,32'h00000003);
                ev(EV_BOTH_ON_CLEAR);
            join
            rd('h0c,32'h00000003);
            // WSTRB[0]=0: W1C가 무시되어 두 비트가 유지된다.
            wr('h0c,32'h00000003,4'b0000);
            rd('h0c,32'h00000003);

            // RO 레지스터와 리셋 후 상태 초기화 확인.
            rd('h18,32'h00010000);
            rd('h1c,32'h524D4150);
            ev(EV_ASSERT_RESET);
            ev(EV_RELEASE);
            rd('h0c,32'h00000000);
            rd('h00,32'h00000000);
            rd('h10,32'h00000000);
        endtask
    endclass

    class axi22_env extends uvm_env;
        `uvm_component_utils(axi22_env)
        axi22_bus_agent bus_agent;
        irq22_event_agent event_agent;
        axi22_virtual_sequencer vsqr;
        axi22_scoreboard sb;
        function new(string name,uvm_component parent);
            super.new(name,parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            bus_agent=axi22_bus_agent::type_id::create("bus_agent",this);
            event_agent=irq22_event_agent::type_id::create("event_agent",this);
            vsqr=axi22_virtual_sequencer::type_id::create("vsqr",this);
            sb=axi22_scoreboard::type_id::create("sb",this);
        endfunction
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            vsqr.bus_sqr=bus_agent.sqr;
            vsqr.evt_sqr=event_agent.sqr;
            bus_agent.mon.ap.connect(sb.bus_in);
            event_agent.mon.ap.connect(sb.irq_in);
        endfunction
    endclass

    class axi22_test extends uvm_test;
        `uvm_component_utils(axi22_test)
        axi22_env env;
        virtual irq22_if irq_vif;
        bit done=0;
        function new(string name,uvm_component parent);
            super.new(name,parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env=axi22_env::type_id::create("env",this);
            if (!uvm_config_db#(virtual irq22_if)::get(this,"","vif",irq_vif))
                `uvm_fatal("TEST_VIF","IRQ virtual interface missing")
        endfunction
        task run_phase(uvm_phase phase);
            axi22_system_sequence vseq;
            phase.raise_objection(this);
            repeat (4) @(negedge irq_vif.clk);
            vseq=axi22_system_sequence::type_id::create("vseq");
            vseq.start(env.vsqr);
            done=1;
            phase.drop_objection(this);
        endtask
        function void check_phase(uvm_phase phase);
            super.check_phase(phase);
            if (!done || env.sb.writes!=6 || env.sb.reads!=13 ||
                env.sb.events!=4 || env.sb.resets!=2 ||
                env.sb.collisions!=1 || env.sb.zero_strobes!=1 ||
                env.sb.commits!=6 || env.sb.committed.size()!=0 ||
                env.bus_agent.drv.driven!=19 ||
                env.event_agent.drv.events_driven!=6 ||
                env.bus_agent.mon.aw_seen || env.bus_agent.mon.w_seen ||
                env.bus_agent.mon.ar_seen)
                `uvm_fatal("COUNT","Incomplete multi-agent verification")
        endfunction
        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            if (uvm_report_server::get_server().get_severity_count(UVM_ERROR)!=0 ||
                uvm_report_server::get_server().get_severity_count(UVM_FATAL)!=0)
                `uvm_fatal("REPORT","UVM error or fatal reported")
            `uvm_info("RESULT","PASS CH22 AXI_W=6 AXI_R=13 IRQ=4 RESET=2 COLLISION=1 ZERO=1",UVM_NONE)
        endfunction
    endclass
endpackage

module tb_axi_multiagent_irq;
    import uvm_pkg::*;
    import ch22_pkg::*;
    logic clk=0;
    always #5 clk=~clk;
    irq22_if irq_bus(clk);
    axi22_if axi_bus(clk,irq_bus.resetn);

    wire wr_en;
    wire [7:0] wr_offset,rd_offset;
    wire [31:0] wr_data,rd_data;
    wire [3:0] wr_strb;
    wire enable_o,start_pulse_o,clear_pulse_o;
    wire [1:0] mode_o;
    wire [31:0] data_in_o;

    axi4lite_slave_adapter axi_dut (
        .s_axi_aclk(clk),.s_axi_aresetn(irq_bus.resetn),
        .s_axi_awaddr(axi_bus.awaddr),.s_axi_awprot(3'b000),
        .s_axi_awvalid(axi_bus.awvalid),.s_axi_awready(axi_bus.awready),
        .s_axi_wdata(axi_bus.wdata),.s_axi_wstrb(axi_bus.wstrb),
        .s_axi_wvalid(axi_bus.wvalid),.s_axi_wready(axi_bus.wready),
        .s_axi_bresp(axi_bus.bresp),.s_axi_bvalid(axi_bus.bvalid),
        .s_axi_bready(axi_bus.bready),
        .s_axi_araddr(axi_bus.araddr),.s_axi_arprot(3'b000),
        .s_axi_arvalid(axi_bus.arvalid),.s_axi_arready(axi_bus.arready),
        .s_axi_rdata(axi_bus.rdata),.s_axi_rresp(axi_bus.rresp),
        .s_axi_rvalid(axi_bus.rvalid),.s_axi_rready(axi_bus.rready),
        .wr_en(wr_en),.wr_offset(wr_offset),.wr_data(wr_data),
        .wr_strb(wr_strb),.rd_offset(rd_offset),.rd_data(rd_data)
    );

    custom_register_bank bank (
        .clk(clk),.resetn(irq_bus.resetn),.wr_en(wr_en),
        .wr_offset(wr_offset),.wr_data(wr_data),.wr_strb(wr_strb),
        .rd_offset(rd_offset),.rd_data(rd_data),
        .busy_i(1'b0),.done_i(1'b0),.error_i(1'b0),
        .irq_done_event_i(irq_bus.done_event),
        .irq_error_event_i(irq_bus.error_event),
        .data_out_i(32'h12345678),
        .enable_o(enable_o),.mode_o(mode_o),
        .start_pulse_o(start_pulse_o),.clear_pulse_o(clear_pulse_o),
        .data_in_o(data_in_o),.irq_status_o(irq_bus.irq_status)
    );

    // (추가) 관찰용 연결만 추가, 원본 DUT 포트와 동작은 유지.
    assign irq_bus.wr_en=wr_en;
    assign irq_bus.wr_offset=wr_offset;
    assign irq_bus.wr_data=wr_data;
    assign irq_bus.wr_strb=wr_strb;

    initial begin
        uvm_config_db#(virtual axi22_if)::set(
            null,"uvm_test_top.env.bus_agent.*","vif",axi_bus);
        uvm_config_db#(virtual irq22_if)::set(
            null,"uvm_test_top.env.event_agent.*","vif",irq_bus);
        uvm_config_db#(virtual irq22_if)::set(null,"uvm_test_top","vif",irq_bus);
        run_test("axi22_test");
    end
    initial begin
        #100000;
        $fatal(1,"CH22 GLOBAL_TIMEOUT");
    end
endmodule
