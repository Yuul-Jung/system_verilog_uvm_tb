`timescale 1ns/1ps
// 제19장: Sequence → Sequencer → Driver와 분리된 Monitor/Agent/Scoreboard.
// 원본 pwm_core.v의 포트·RTL은 수정하지 않는다.
// 입력 요청 2→6→0의 기대값은 Scoreboard가 독립적으로 관리한다.

interface pwm19_if(input logic clk);
    logic resetn = 1'b0;
    logic cfg_apply = 1'b0;
    logic [31:0] cfg_period = 32'd8;
    logic [31:0] cfg_duty = 32'd0;
    logic cfg_enable = 1'b0;
    logic cfg_polarity = 1'b0;
    wire pwm_out, pending, active_enable, active_polarity;
    wire [31:0] active_period, active_duty;
endinterface

package ch19_uvm_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // (추가) Sequence가 Driver로 보내는 설정 거래.
    class pwm19_item extends uvm_sequence_item;
        bit [31:0] duty;
        `uvm_object_utils(pwm19_item)
        function new(string name="pwm19_item");
            super.new(name);
        endfunction
    endclass

    // (추가) Monitor가 관찰한 공개 신호를 담는 별도 거래.
    class pwm19_sample extends uvm_sequence_item;
        // (변경) 매 에지의 입력과 출력 모두 보존. X/Z도 유지한다.
        logic resetn, cfg_apply;
        logic [31:0] cfg_duty, cfg_period;
        logic cfg_enable, cfg_polarity;
        logic [31:0] duty, period;
        logic enable, polarity, pending, pwm;
        time sampled_at;
        `uvm_object_utils(pwm19_sample)
        function new(string name="pwm19_sample");
            super.new(name);
        endfunction
    endclass

    // (유지/확장) 제18장의 2, 6, 0 듀티 순서를 그대로 재사용.
    class pwm19_sequence extends uvm_sequence #(pwm19_item);
        `uvm_object_utils(pwm19_sequence)
        function new(string name="pwm19_sequence");
            super.new(name);
        endfunction
        task body();
            pwm19_item req;
            for (int i=0; i<3; i++) begin
                req = pwm19_item::type_id::create($sformatf("req_%0d", i));
                start_item(req);
                case (i)
                    0: req.duty = 32'd2;
                    1: req.duty = 32'd6;
                    default: req.duty = 32'd0;
                endcase
                finish_item(req);
            end
        endtask
    endclass

    class pwm19_sequencer extends uvm_sequencer #(pwm19_item);
        `uvm_component_utils(pwm19_sequencer)
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
    endclass

    // (변경) Driver는 입력 신호만 구동하고 응답의 정답 판정은 하지 않는다.
    class pwm19_driver extends uvm_driver #(pwm19_item);
        `uvm_component_utils(pwm19_driver)
        virtual pwm19_if vif;
        int unsigned driven = 0;
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual pwm19_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "pwm19_if missing")
        endfunction
        task drive_one(pwm19_item req);
            int guard;
            @(negedge vif.clk);
            vif.cfg_period = 32'd8;
            vif.cfg_duty = req.duty;
            vif.cfg_enable = 1'b1;
            vif.cfg_polarity = 1'b0;
            vif.cfg_apply = 1'b1;
            @(negedge vif.clk);
            vif.cfg_apply = 1'b0;

            // 대기 신호를 통해 다음 요청을 언제 보낼지만 제어한다.
            // 실제 적용 듀티·출력 판정은 Monitor/Scoreboard의 책임.
            guard = 0;
            while (vif.pending !== 1'b0) begin
                @(negedge vif.clk);
                guard++;
                if (guard > 12)
                    `uvm_fatal("DRV_TIMEOUT", "pending was not cleared")
            end
            driven++;
        endtask
        task run_phase(uvm_phase phase);
            pwm19_item req;
            forever begin
                seq_item_port.get_next_item(req);
                drive_one(req);
                seq_item_port.item_done();
            end
        endtask
    endclass

    // (추가) Monitor는 DUT 출력/입력을 관찰할 뿐 신호를 구동하지 않는다.
    class pwm19_monitor extends uvm_monitor;
        `uvm_component_utils(pwm19_monitor)
        virtual pwm19_if vif;
        uvm_analysis_port #(pwm19_sample) ap;

        function new(string name, uvm_component parent);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual pwm19_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "pwm19_if missing")
        endfunction
        task run_phase(uvm_phase phase);
            pwm19_sample sample;
            forever begin
                @(posedge vif.clk);
                #1; // DUT의 비차단 대입 완료 이후 공개 출력 관찰
                // (변경) 이벤트를 추론하지 않고 매 에지마다 새 객체를 전송한다.
                sample = pwm19_sample::type_id::create("cycle_sample");
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
                // (추가) 정상 DUT가 아닌 관찰 객체만 변경하는 부정 시험.
                if ($test$plusargs("CORRUPT_SAMPLE") && sample.sampled_at == 126)
                    sample.pwm = ~sample.pwm;
                ap.write(sample);
            end
        endtask
    endclass

    // (추가) Analysis Imp를 통해 Monitor의 관찰 거래를 받는다.
    // '정답 2→6→0'은 DUT에서 읽지 않고 검증 기준으로 별도 보관.
    class pwm19_scoreboard extends uvm_scoreboard;
        `uvm_component_utils(pwm19_scoreboard)
        uvm_analysis_imp #(pwm19_sample, pwm19_scoreboard) analysis_export;
        int unsigned requests = 0;
        int unsigned applied = 0;
        bit [31:0] planned_duty[3] = '{32'd2, 32'd6, 32'd0};
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

        // (변경) 예상 위상은 DUT의 pending/counter가 아니라 리셋 후
        // 관찰 클록 수의 나머지로 계산한다. 이 실습은 period=8 고정.
        function void write(pwm19_sample sample);
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
                if (applied >= requests || applied >= 3)
                    `uvm_fatal("SB_ORDER", "Apply without request")
                expected_duty = planned_duty[applied];
                expected_enable = 1;
                expected_pending = 0;
                if (sample.sampled_at - request_time[applied] > 80)
                    `uvm_fatal("SB_LATENCY", "Apply exceeded one period")
                applied++;
                `uvm_info("SB", $sformatf("APPLIED %0d duty=%0d",
                    applied, expected_duty), UVM_LOW)
            end
            // 요청의 예상 순서는 Driver의 거래 객체에 의존하지 않는다.
            if (sample.cfg_apply === 1'b1) begin
                if (requests >= 3 || expected_pending)
                    `uvm_fatal("SB_EXTRA", "Unexpected or overlapping request")
                if (sample.cfg_period !== 32'd8 ||
                    sample.cfg_duty !== planned_duty[requests] ||
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

    // (추가) Agent가 Sequencer, Driver, Monitor를 한 단위로 묶는다.
    class pwm19_agent extends uvm_agent;
        `uvm_component_utils(pwm19_agent)
        pwm19_sequencer sqr;
        pwm19_driver drv;
        pwm19_monitor mon;
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            sqr = pwm19_sequencer::type_id::create("sqr", this);
            drv = pwm19_driver::type_id::create("drv", this);
            mon = pwm19_monitor::type_id::create("mon", this);
        endfunction
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            drv.seq_item_port.connect(sqr.seq_item_export);
        endfunction
    endclass

    class pwm19_env extends uvm_env;
        `uvm_component_utils(pwm19_env)
        pwm19_agent ag;
        pwm19_scoreboard sb;
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            ag = pwm19_agent::type_id::create("ag", this);
            sb = pwm19_scoreboard::type_id::create("sb", this);
        endfunction
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            ag.mon.ap.connect(sb.analysis_export);
        endfunction
    endclass

    class pwm19_test extends uvm_test;
        `uvm_component_utils(pwm19_test)
        virtual pwm19_if vif;
        pwm19_env env;
        bit seq_finished = 0;
        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = pwm19_env::type_id::create("env", this);
            if (!uvm_config_db#(virtual pwm19_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "pwm19_if missing in test")
        endfunction
        task run_phase(uvm_phase phase);
            pwm19_sequence seq;
            phase.raise_objection(this);
            repeat (3) @(negedge vif.clk);
            if (vif.active_period !== 32'd8 ||
                vif.active_duty !== 32'd0 || vif.pending !== 1'b0)
                `uvm_fatal("RESET", "PWM reset did not complete")
            vif.resetn = 1'b1;
            seq = pwm19_sequence::type_id::create("seq");
            seq.start(env.ag.sqr);
            seq_finished = 1;
            // (변경) 마지막 거래 적용 이후 전체 주기의 관찰까지 기다린다.
            wait (env.sb.samples == 24);
            @(negedge vif.clk);
            phase.drop_objection(this);
        endtask
        function void check_phase(uvm_phase phase);
            super.check_phase(phase);
            if (!seq_finished || env.ag.drv.driven != 3 ||
                env.sb.requests != 3 || env.sb.applied != 3 ||
                env.sb.samples != 24 || env.sb.cycles != 31 ||
                env.sb.reset_samples != 3 || env.sb.expected_pending)
                `uvm_fatal("SB_COUNT", "Missing or extra observations")
        endfunction
        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            if (uvm_report_server::get_server().get_severity_count(UVM_ERROR) != 0 ||
                uvm_report_server::get_server().get_severity_count(UVM_FATAL) != 0)
                `uvm_fatal("REPORT", "UVM error or fatal reported")
            `uvm_info("RESULT", "PASS CH19 requests=3 applied=3 samples=24", UVM_NONE)
        endfunction
    endclass
endpackage

module tb_pwm_monitor_agent_scoreboard;
    import uvm_pkg::*;
    import ch19_uvm_pkg::*;

    logic clk = 1'b0;
    always #5 clk = ~clk;
    pwm19_if bus(clk);

    pwm_core #(.RESET_PERIOD(32'd8)) dut (
        .clk(clk), .resetn(bus.resetn), .cfg_apply(bus.cfg_apply),
        .cfg_period(bus.cfg_period), .cfg_duty(bus.cfg_duty),
        .cfg_enable(bus.cfg_enable), .cfg_polarity(bus.cfg_polarity),
        .pwm_out(bus.pwm_out), .pending(bus.pending),
        .active_period(bus.active_period), .active_duty(bus.active_duty),
        .active_enable(bus.active_enable),
        .active_polarity(bus.active_polarity)
    );

    initial begin
        uvm_config_db#(virtual pwm19_if)::set(null, "uvm_test_top", "vif", bus);
        uvm_config_db#(virtual pwm19_if)::set(null, "uvm_test_top.env.ag.drv", "vif", bus);
        uvm_config_db#(virtual pwm19_if)::set(null, "uvm_test_top.env.ag.mon", "vif", bus);
        run_test("pwm19_test");
    end
    initial begin
        #2000;
        $fatal(1, "FAIL CH19 GLOBAL_TIMEOUT");
    end
endmodule
