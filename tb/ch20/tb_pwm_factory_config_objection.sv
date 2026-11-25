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
            if (!uvm_config_db#(pwm20_cfg)::get(this, "", "cfg", cfg) || cfg == null)
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

    class pwm20_sample extends uvm_sequence_item;
        // (변경) 매 에지의 입력과 출력 모두 보존. X/Z도 유지한다.
        logic resetn, cfg_apply;
        logic [31:0] cfg_duty, cfg_period;
        logic cfg_enable, cfg_polarity;
        logic [31:0] duty, period;
        logic enable, polarity, pending, pwm;
        time sampled_at;
        `uvm_object_utils(pwm20_sample)
        function new(string name="pwm20_sample");
            super.new(name);
        endfunction
    endclass

    // (변경) 제19장의 매 클록 관찰과 독립 모델을 유지한다.
    class pwm20_monitor extends uvm_monitor;
        `uvm_component_utils(pwm20_monitor)
        virtual pwm20_if vif;
        uvm_analysis_port #(pwm20_sample) ap;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual pwm20_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "pwm20_if missing")
        endfunction
        task run_phase(uvm_phase phase);
            pwm20_sample sample;
            forever begin
                @(posedge vif.clk);
                #1; // DUT의 비차단 대입 완료 이후 공개 출력 관찰
                // (변경) 이벤트를 추론하지 않고 매 에지마다 새 객체를 전송한다.
                sample = pwm20_sample::type_id::create("cycle_sample");
                sample.resetn = vif.resetn;
                sample.cfg_apply = vif.cfg_apply;
                sample.cfg_duty = vif.cfg_duty;
                sample.cfg_period = vif.cfg_period;
                sample.cfg_enable = vif.cfg_enable;
                sample.cfg_polarity = vif.cfg_polarity;
                sample.duty = vif.active_duty;
                sample.period = vif.active_period;
                sample.enable = vif.active_enable;
                sample.polarity = vif.active_polarity;
                sample.pending = vif.pending;
                sample.pwm = vif.pwm_out;
                sample.sampled_at = $time;
                ap.write(sample);
            end
        endtask
    endclass

    class pwm20_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(pwm20_scoreboard)
        uvm_analysis_imp #(pwm20_sample, pwm20_scoreboard) analysis_export;
        int unsigned requests = 0;
        int unsigned applied = 0;
        pwm20_cfg cfg;
        time request_time[3];
        int unsigned reset_samples = 0, cycles = 0, samples = 0;
        int unsigned phase_idx = 0;
        bit expected_pending = 0, expected_enable = 0;
        bit [31:0] expected_duty = 0;
        bit expected_pwm;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            analysis_export = new("analysis_export", this);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(pwm20_cfg)::get(this, "", "cfg", cfg) || cfg == null)
                `uvm_fatal("NO_CFG", "Scoreboard config not found")
        endfunction

        // (변경) 예상 위상은 DUT의 pending/counter가 아니라 리셋 후
        // 관찰 클록 수의 나머지로 계산한다. 이 실습은 period=8 고정.
        function void write(pwm20_sample sample);
            if (sample.resetn === 1'b0) begin
                if (cycles != 0)
                    `uvm_fatal("SB_RESET", "Unexpected reset during transactions")
                reset_samples++;
                if (sample.period !== 32'd8 || sample.duty !== 32'd0 ||
                    sample.enable !== 1'b0 || sample.polarity !== 1'b0 ||
                    sample.pending !== 1'b0 || sample.pwm !== 1'b0)
                    `uvm_fatal("SB_RESET", "Reset output mismatch")
                return;
            end
            if (sample.resetn !== 1'b1 || reset_samples != 3)
                `uvm_fatal("SB_RESET", "Reset sequence mismatch")
            cycles++;
            phase_idx = cycles % 8;

            // 주기 경계에서는 이전 요청만 적용된다.
            if (phase_idx == 0 && expected_pending) begin
                if (applied >= requests || applied >= cfg.expected_transactions)
                    `uvm_fatal("SB_ORDER", "Apply without request")
                expected_duty = cfg.duty_plan[applied];
                expected_enable = 1;
                expected_pending = 0;
                if (sample.sampled_at - request_time[applied] > cfg.max_apply_ns)
                    `uvm_fatal("SB_LATENCY", "Apply exceeded one period")
                applied++;
                `uvm_info("SB", $sformatf("APPLIED %0d duty=%0d",
                    applied, expected_duty), UVM_LOW)
            end
            // 요청의 예상 순서는 Driver의 거래 객체에 의존하지 않는다.
            if (sample.cfg_apply === 1'b1) begin
                if (requests >= cfg.expected_transactions || expected_pending)
                    `uvm_fatal("SB_EXTRA", "Unexpected or overlapping request")
                if (sample.cfg_period !== 32'd8 ||
                    sample.cfg_duty !== cfg.duty_plan[requests] ||
                    sample.cfg_enable !== 1'b1 || sample.cfg_polarity !== 1'b0)
                    `uvm_fatal("SB_REQUEST", "Unexpected PWM request content")
                request_time[requests] = sample.sampled_at;
                requests++;
                expected_pending = 1;
                `uvm_info("SB", $sformatf("REQUEST %0d duty=%0d",
                    requests, sample.cfg_duty), UVM_LOW)
            end else if (sample.cfg_apply !== 1'b0)
                `uvm_fatal("SB_REQUEST", "Unknown cfg_apply")

            // 실제 공개 출력과 독립 기대값을 매 에지에서 대조한다.
            if (sample.period !== 32'd8 || sample.duty !== expected_duty ||
                sample.enable !== expected_enable || sample.polarity !== 1'b0 ||
                sample.pending !== expected_pending)
                `uvm_fatal("SB_STATE", $sformatf("t=%0d phase=%0d",
                    sample.sampled_at, phase_idx))
            expected_pwm = expected_enable && (phase_idx < expected_duty);
            if (sample.pwm !== expected_pwm)
                `uvm_fatal("SB_PWM", $sformatf("t=%0d phase=%0d expected=%0b got=%0b",
                    sample.sampled_at, phase_idx, expected_pwm, sample.pwm))
            if (expected_enable) samples++;
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
        pwm20_traced_driver traced;
        bit seq_finished = 0;
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            settings = pwm20_cfg::type_id::create("settings");
            // (추가) 설정 객체만 변경하여 동일한 환경을 재사용한다.
            if ($test$plusargs("ALT_PLAN")) begin
                settings.duty_plan[0] = 32'd1;
                settings.duty_plan[1] = 32'd8;
                settings.duty_plan[2] = 32'd3;
            end
            // 고정 길이 배열의 범위를 벗어나지 않도록 계약을 확인한다.
            if (settings.expected_transactions != 3)
                `uvm_fatal("CFG_RANGE", "Expected exactly three transactions")
            foreach (settings.duty_plan[i])
                if (settings.duty_plan[i] > 8)
                    `uvm_fatal("CFG_RANGE", "Duty must be 0..8")
            if (!uvm_config_db#(virtual pwm20_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "Test interface missing")

            // Factory Override는 env.build_phase() 실행 이전에 등록한다.
            if (!$test$plusargs("NO_OVERRIDE"))
                pwm20_driver::type_id::set_type_override(
                    pwm20_traced_driver::get_type());

            // Config DB는 구성 값을 계층 아래에 공유한다.
            // (변경) 필요한 두 컴포넌트에만 설정을 전달한다.
            if (!$test$plusargs("NO_CFG"))
                uvm_config_db#(pwm20_cfg)::set(this, "env.ag.drv", "cfg", settings);
            uvm_config_db#(pwm20_cfg)::set(this, "env.sb", "cfg", settings);
            env = pwm20_env::type_id::create("env", this);
        endfunction

        task run_phase(uvm_phase phase);
            pwm20_sequence seq;

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

            // (추가) 실제로 같은 설정 객체를 받았는지 확인한다.
            if (env.ag.drv.cfg != settings || env.sb.cfg != settings)
                `uvm_fatal("CFG_IDENTITY", "Config handle mismatch")
            seq = pwm20_sequence::type_id::create("seq");
            seq.cfg = settings;
            seq.start(env.ag.sqr);
            seq_finished = 1;
            // (변경) 마지막 전체 주기 관찰까지 종료를 보류한다.
            // EARLY_DROP는 종료 검사의 부정 시험 전용이다.
            if (!$test$plusargs("EARLY_DROP")) begin
                wait (env.sb.samples == 24);
                @(negedge vif.clk);
            end
            phase.drop_objection(this);
        endtask

        function void check_phase(uvm_phase phase);
            super.check_phase(phase);
            if (!seq_finished || traced == null ||
                env.ag.drv.driven != 3 || traced.trace_count != 3 ||
                env.sb.requests != 3 || env.sb.applied != 3 ||
                env.sb.samples != 24 || env.sb.cycles != 31 ||
                env.sb.reset_samples != 3 || env.sb.expected_pending)
                `uvm_fatal("COUNTS", $sformatf("Incomplete verification samples=%0d",
                    env.sb.samples))
        endfunction

        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            if (uvm_report_server::get_server().get_severity_count(UVM_ERROR) != 0 ||
                uvm_report_server::get_server().get_severity_count(UVM_FATAL) != 0)
                `uvm_fatal("REPORT", "UVM error or fatal reported")
            `uvm_info("RESULT", $sformatf(
                "PASS CH20 factory=traced plan=%0d,%0d,%0d applied=3 samples=24",
                settings.duty_plan[0], settings.duty_plan[1], settings.duty_plan[2]), UVM_NONE)
        endfunction
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
        uvm_config_db#(virtual pwm20_if)::set(null, "uvm_test_top", "vif", bus);
        uvm_config_db#(virtual pwm20_if)::set(null, "uvm_test_top.env.ag.drv", "vif", bus);
        uvm_config_db#(virtual pwm20_if)::set(null, "uvm_test_top.env.ag.mon", "vif", bus);
        run_test("pwm20_test");
    end
    initial begin
        #2000;
        $fatal(1, "FAIL CH20 GLOBAL_TIMEOUT");
    end
endmodule
