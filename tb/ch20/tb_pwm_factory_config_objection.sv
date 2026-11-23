`timescale 1ns/1ps
// 제20장: Factory Override + Config DB + Objection의 역할을 분리한다.
// DUT는 읽기 전용 reference_rtl/pwm_core.v, 원본 포트만 연결한다.
// PART 05의 제18~19장과 동일하게 듀티 2 → 6 → 0을 검증한다.
interface pwm20_if(input logic clk);
    logic        resetn = 1'b0;
    logic        cfg_apply = 1'b0;
    logic [31:0] cfg_period = 32'd8;
    logic [31:0] cfg_duty = 32'd0;
    logic        cfg_enable = 1'b0;
    logic        cfg_polarity = 1'b0;
    wire         pwm_out, pending, active_enable, active_polarity;
    wire [31:0]  active_period, active_duty;
endinterface

package ch20_uvm_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // (추가) Config DB에서 공유할 검증 설정 객체.
    // DUT 출력에서 기대값을 복사하지 않고 테스트의 계약을 저장한다.
    class pwm20_cfg extends uvm_object;
        `uvm_object_utils(pwm20_cfg)
        bit [31:0] duty_plan[3];
        int unsigned max_wait_cycles;
        time max_apply_ns;
        int unsigned expected_transactions;
        bit enable_trace;
        function new(string name="pwm20_cfg");
            super.new(name);
            duty_plan[0] = 32'd2;
            duty_plan[1] = 32'd6;
            duty_plan[2] = 32'd0;
            max_wait_cycles = 12;
            max_apply_ns = 80;
            expected_transactions = 3;
            enable_trace = 1'b1;
        endfunction
    endclass

    class pwm20_item extends uvm_sequence_item;
        `uvm_object_utils(pwm20_item)
        bit [31:0] duty;
        function new(string name="pwm20_item");
            super.new(name);
        endfunction
    endclass

    class pwm20_sequence extends uvm_sequence #(pwm20_item);
        `uvm_object_utils(pwm20_sequence)
        pwm20_cfg cfg;
        function new(string name="pwm20_sequence");
            super.new(name);
        endfunction
        task body();
            pwm20_item req;
            if (cfg == null)
                `uvm_fatal("SEQ_CFG", "Sequence config not provided")
            for (int i=0; i<int'(cfg.expected_transactions); i++) begin
                req = pwm20_item::type_id::create($sformatf("req_%0d", i));
                start_item(req);
                req.duty = cfg.duty_plan[i];
                finish_item(req);
            end
        endtask
    endclass

    class pwm20_sequencer extends uvm_sequencer #(pwm20_item);
        `uvm_component_utils(pwm20_sequencer)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
    endclass

    // (추가) 기본 Driver: 객체·인터페이스·설정만으로 일반적 구동을 수행.
    // 동작 변경이나 로그 추가는 원본 DUT가 아니라 Factory Override로 처리.
    class pwm20_driver extends uvm_driver #(pwm20_item);
        `uvm_component_utils(pwm20_driver)
        virtual pwm20_if vif;
        pwm20_cfg cfg;
        int unsigned driven = 0;
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual pwm20_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "pwm20_if not configured")
            if (!uvm_config_db#(pwm20_cfg)::get(this, "", "cfg", cfg))
                `uvm_fatal("NO_CFG", "Driver config not found")
        endfunction
        virtual task drive_one(pwm20_item req);
            int unsigned guard;
            @(negedge vif.clk);
            vif.cfg_period = 32'd8;
            vif.cfg_duty = req.duty;
            vif.cfg_enable = 1'b1;
            vif.cfg_polarity = 1'b0;
            vif.cfg_apply = 1'b1;
            @(negedge vif.clk);
            vif.cfg_apply = 1'b0;

            // 이 Driver는 다음 입력을 보낼 타이밍만 제어한다.
            // 요청·적용 데이터의 정답은 Scoreboard가 별도로 검사한다.
            guard = 0;
            while (vif.pending !== 1'b0) begin
                @(negedge vif.clk);
                guard++;
                if (guard > cfg.max_wait_cycles)
                    `uvm_fatal("DRV_TIMEOUT", "Pending did not clear")
            end
            driven++;
        endtask
        task run_phase(uvm_phase phase);
            pwm20_item req;
            forever begin
                seq_item_port.get_next_item(req);
                drive_one(req);
                seq_item_port.item_done();
            end
        endtask
    endclass

    // (추가) 기본 Driver를 수정하지 않고 로깅만 덧붙이는 교체 구현.
    class pwm20_traced_driver extends pwm20_driver;
        `uvm_component_utils(pwm20_traced_driver)
        int unsigned trace_count = 0;
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        virtual task drive_one(pwm20_item req);
            if (cfg.enable_trace)
                `uvm_info("FACTORY_TRACE",
                    $sformatf("DRIVE duty=%0d", req.duty), UVM_LOW)
            super.drive_one(req);
            trace_count++;
        endtask
    endclass

    typedef enum {PWM20_REQUEST, PWM20_APPLIED} pwm20_kind_e;
    class pwm20_sample extends uvm_sequence_item;
        `uvm_object_utils(pwm20_sample)
        pwm20_kind_e kind;
        logic [31:0] duty, period;
        logic enable, polarity, pending, pwm;
        time sampled_at;
        function new(string name="pwm20_sample");
            super.new(name);
        endfunction
    endclass

    // (유지/확장) Monitor: 공개 입력과 출력을 관찰만 하며 구동하지 않는다.
    class pwm20_monitor extends uvm_monitor;
        `uvm_component_utils(pwm20_monitor)
        virtual pwm20_if vif;
        uvm_analysis_port #(pwm20_sample) ap;
        bit previous_pending = 1'b0;
        function new(string name, uvm_component parent);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual pwm20_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "Monitor interface missing")
        endfunction
        task run_phase(uvm_phase phase);
            pwm20_sample s;
            forever begin
                @(posedge vif.clk);
                #1; // 상승 에지의 비차단 대입 완료 이후 읽는다.
                if (!vif.resetn) begin
                    previous_pending = 1'b0;
                end else begin
                    if (vif.cfg_apply === 1'b1) begin
                        s = pwm20_sample::type_id::create("req_sample");
                        s.kind = PWM20_REQUEST;
                        s.duty = vif.cfg_duty;
                        s.period = vif.cfg_period;
                        s.enable = vif.cfg_enable;
                        s.polarity = vif.cfg_polarity;
                        s.pending = vif.pending;
                        s.pwm = vif.pwm_out;
                        s.sampled_at = $time;
                        ap.write(s);
                    end
                    if (previous_pending && vif.pending === 1'b0) begin
                        s = pwm20_sample::type_id::create("applied_sample");
                        s.kind = PWM20_APPLIED;
                        s.duty = vif.active_duty;
                        s.period = vif.active_period;
                        s.enable = vif.active_enable;
                        s.polarity = vif.active_polarity;
                        s.pending = vif.pending;
                        s.pwm = vif.pwm_out;
                        s.sampled_at = $time;
                        ap.write(s);
                    end
                    previous_pending = (vif.pending === 1'b1);
                end
            end
        endtask
    endclass

    // (추가) Scoreboard는 Config DB 설정을 읽어 계획값과 비교한다.
    class pwm20_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(pwm20_scoreboard)
        uvm_analysis_imp #(pwm20_sample, pwm20_scoreboard) analysis_export;
        pwm20_cfg cfg;
        int unsigned requests = 0, applied = 0;
        time request_time[3];
        function new(string name, uvm_component parent);
            super.new(name, parent);
            analysis_export = new("analysis_export", this);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(pwm20_cfg)::get(this, "", "cfg", cfg))
                `uvm_fatal("NO_CFG", "Scoreboard config not found")
        endfunction
        function void write(pwm20_sample s);
            if (s.kind == PWM20_REQUEST) begin
                if (requests >= cfg.expected_transactions)
                    `uvm_fatal("EXTRA_REQUEST", "More requests than configured")
                if (s.period !== 32'd8 ||
                    s.duty !== cfg.duty_plan[requests] ||
                    s.enable !== 1'b1 || s.polarity !== 1'b0 ||
                    s.pending !== 1'b1)
                    `uvm_fatal("REQ_MISMATCH", "Request was not as configured")
                request_time[requests] = s.sampled_at;
                requests++;
                `uvm_info("SCOREBOARD",
                    $sformatf("REQUEST %0d", requests), UVM_LOW)
            end else if (s.kind == PWM20_APPLIED) begin
                if (applied >= requests || applied >= cfg.expected_transactions)
                    `uvm_fatal("APPLY_ORDER", "Applied event without request")
                if (s.period !== 32'd8 ||
                    s.duty !== cfg.duty_plan[applied] ||
                    s.enable !== 1'b1 || s.polarity !== 1'b0 ||
                    s.pending !== 1'b0 ||
                    s.pwm !== (cfg.duty_plan[applied] != 0))
                    `uvm_fatal("APPLY_MISMATCH", "PWM active setting mismatch")
                if (s.sampled_at < request_time[applied] ||
                    s.sampled_at - request_time[applied] > cfg.max_apply_ns)
                    `uvm_fatal("APPLY_LATENCY", "Applied after allowed deadline")
                applied++;
                `uvm_info("SCOREBOARD",
                    $sformatf("APPLIED %0d", applied), UVM_LOW)
            end else begin
                `uvm_fatal("UNKNOWN_EVENT", "Unexpected monitor event kind")
            end
        endfunction
    endclass

    // (유지) Agent는 Driver를 기반 클래스 타입으로 factory 생성한다.
    // 실제 객체는 Test의 Override 정책에 따라 traced_driver가 된다.
    class pwm20_agent extends uvm_agent;
        `uvm_component_utils(pwm20_agent)
        pwm20_sequencer sqr;
        pwm20_driver drv;
        pwm20_monitor mon;
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            sqr = pwm20_sequencer::type_id::create("sqr", this);
            drv = pwm20_driver::type_id::create("drv", this);
            mon = pwm20_monitor::type_id::create("mon", this);
        endfunction
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            drv.seq_item_port.connect(sqr.seq_item_export);
        endfunction
    endclass

    class pwm20_env extends uvm_env;
        `uvm_component_utils(pwm20_env)
        pwm20_agent ag;
        pwm20_scoreboard sb;
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            ag = pwm20_agent::type_id::create("ag", this);
            sb = pwm20_scoreboard::type_id::create("sb", this);
        endfunction
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            ag.mon.ap.connect(sb.analysis_export);
        endfunction
    endclass

    // (추가) Factory/Config/Objection의 책임은 Test에 집중한다.
    class pwm20_test extends uvm_test;
        `uvm_component_utils(pwm20_test)
        pwm20_cfg settings;
        virtual pwm20_if vif;
        pwm20_env env;
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            settings = pwm20_cfg::type_id::create("settings");
            if (!uvm_config_db#(virtual pwm20_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "Test interface missing")

            // Factory Override는 env.build_phase() 실행 이전에 등록한다.
            pwm20_driver::type_id::set_type_override(
                pwm20_traced_driver::get_type());

            // Config DB는 구성 값을 계층 아래에 공유한다.
            uvm_config_db#(pwm20_cfg)::set(this, "env.*", "cfg", settings);
            env = pwm20_env::type_id::create("env", this);
        endfunction

        task run_phase(uvm_phase phase);
            pwm20_sequence seq;
            pwm20_traced_driver traced;

            // (추가) Objection을 올려 UVM이 Sequence 도중 종료되지 않게 한다.
            phase.raise_objection(this);
            repeat (3) @(negedge vif.clk);
            if (vif.active_period !== 32'd8 ||
                vif.active_duty !== 32'd0 || vif.pending !== 1'b0)
                `uvm_fatal("RESET", "PWM sync reset not confirmed")
            vif.resetn = 1'b1;

            // 실제 생성 객체가 Override된 타입인지 런타임에 확인.
            if (!$cast(traced, env.ag.drv))
                `uvm_fatal("FACTORY", "Driver type override was ignored")

            seq = pwm20_sequence::type_id::create("seq");
            seq.cfg = settings;
            seq.start(env.ag.sqr);
            repeat (2) @(negedge vif.clk);

            // 입력 3건과 Monitor·Scoreboard 적용 관찰 3건을 모두 확인.
            if (env.ag.drv.driven != settings.expected_transactions ||
                traced.trace_count != settings.expected_transactions ||
                env.sb.requests != settings.expected_transactions ||
                env.sb.applied != settings.expected_transactions)
                `uvm_fatal("COUNTS", "Factory/Monitor/Scoreboard count mismatch")
            `uvm_info("RESULT",
                "PASS CH20 factory=traced config=3 applied=3", UVM_NONE)

            // 모든 판정을 마친 뒤 Objection을 내려 종료를 허용한다.
            phase.drop_objection(this);
        endtask
    endclass
endpackage

module tb_pwm_factory_config_objection;
    import uvm_pkg::*;
    import ch20_uvm_pkg::*;
    logic clk = 1'b0;
    always #5 clk = ~clk;
    pwm20_if bus(clk);

    pwm_core #(.RESET_PERIOD(32'd8)) dut (
        .clk(clk), .resetn(bus.resetn),
        .cfg_apply(bus.cfg_apply), .cfg_period(bus.cfg_period),
        .cfg_duty(bus.cfg_duty), .cfg_enable(bus.cfg_enable),
        .cfg_polarity(bus.cfg_polarity), .pwm_out(bus.pwm_out),
        .pending(bus.pending), .active_period(bus.active_period),
        .active_duty(bus.active_duty),
        .active_enable(bus.active_enable),
        .active_polarity(bus.active_polarity)
    );

    initial begin
        $dumpfile("ch20_pwm_factory_config_objection.vcd");
        $dumpvars(0, tb_pwm_factory_config_objection);
        uvm_config_db#(virtual pwm20_if)::set(null, "*", "vif", bus);
        run_test("pwm20_test");
    end
    initial begin
        #2000;
        $fatal(1, "FAIL CH20 GLOBAL_TIMEOUT");
    end
endmodule
