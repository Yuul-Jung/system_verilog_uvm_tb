`timescale 1ns/1ps
// 제17장: 기존 pwm_core를 읽기 전용 DUT로 사용하는 최소 UVM 환경.
// UVM의 build/run/check/report phase와 objection 수명주기를 확인한다.
interface pwm_if(input logic clk);
    logic resetn = 0;
    logic cfg_apply = 0;
    logic [31:0] cfg_period = 8;
    logic [31:0] cfg_duty = 0;
    logic cfg_enable = 0;
    logic cfg_polarity = 0;
    wire pwm_out;
    wire pending;
    wire [31:0] active_period, active_duty;
    wire active_enable, active_polarity;
endinterface

package ch17_uvm_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class pwm_env extends uvm_env;
        `uvm_component_utils(pwm_env)
        virtual pwm_if vif;
        int unsigned checks = 0;
        bit done = 0;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual pwm_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "pwm_if was not provided")
        endfunction

        // (변경) 호출자가 하강 에지에서 관찰 시점을 정한다.
        task automatic expect_ports(
            input logic [31:0] duty, input logic enable,
            input logic expected_pwm
        );
            if (vif.pending !== 1'b0 ||
                vif.active_period !== 32'd8 ||
                vif.active_duty !== duty ||
                vif.active_enable !== enable ||
                vif.active_polarity !== 1'b0 ||
                vif.pwm_out !== expected_pwm)
                `uvm_fatal("MISMATCH", $sformatf(
                    "period=%0d duty=%0d enable=%b pwm=%b",
                    vif.active_period, vif.active_duty,
                    vif.active_enable, vif.pwm_out))
            checks++;
        endtask

        task run_phase(uvm_phase phase);
            // DUT는 동기 리셋: resetn=0인 동안 posedge가 필요하다.
            repeat (3) @(negedge vif.clk);
            if (vif.active_period !== 32'd8 ||
                vif.active_duty !== 32'd0 ||
                vif.active_enable !== 1'b0 || vif.pending !== 1'b0 ||
                vif.active_polarity !== 1'b0 || vif.pwm_out !== 1'b0)
                `uvm_fatal("RESET", "PWM reset contract violated")
            `uvm_info("PWM", "RESET_CHECKED", UVM_LOW)

            // 설정은 Shadow에 저장되고, 다음 주기 경계에서 활성화된다.
            vif.resetn = 1;
            @(negedge vif.clk);
            vif.cfg_period = 8;
            vif.cfg_duty = 4;
            vif.cfg_enable = 1;
            vif.cfg_polarity = 0;
            vif.cfg_apply = 1;
            @(negedge vif.clk);
            vif.cfg_apply = 0;
            if (vif.pending !== 1'b1 || vif.active_duty !== 32'd0 ||
                vif.active_enable !== 1'b0 || vif.pwm_out !== 1'b0)
                `uvm_fatal("PENDING", "cfg_apply was not latched")

            // 8클록 주기 경계가 도래할 때까지 기다린다.
            // 비활성 상태에서 활성 상태로 전환되는 조건만 감시한다.
            begin
                int guard;
                guard = 0;
                while (vif.pending !== 1'b0) begin
                    @(negedge vif.clk);
                    guard++;
                    if (guard > 12)
                        `uvm_fatal("TIMEOUT", "PWM apply boundary timeout")
                end
            end
            if (vif.active_duty !== 32'd4 || vif.active_enable !== 1'b1)
                `uvm_fatal("APPLY", "PWM active settings mismatch")

            // (변경) 경계 직후 phase 0부터 전체 8개 표본을 검사한다.
            for (int i=0; i<8; i++) begin
                expect_ports(32'd4, 1'b1, (i < 4));
                if (i < 7) @(negedge vif.clk);
            end
            `uvm_info("PWM", "PWM_DUTY_CHECKED", UVM_LOW)
            // (추가) 마지막 검사 및 기록 이후에만 완료를 통지한다.
            done = 1;
        endtask

        function void check_phase(uvm_phase phase);
            super.check_phase(phase);
            if (checks != 8 || !done)
                `uvm_fatal("CHECK", $sformatf("checks=%0d", checks))
        endfunction

        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            if (uvm_report_server::get_server().get_severity_count(UVM_ERROR) != 0 ||
                uvm_report_server::get_server().get_severity_count(UVM_FATAL) != 0)
                `uvm_fatal("REPORT", "UVM error or fatal reported")
            `uvm_info("RESULT", $sformatf(
                "PASS CH17 checks=%0d", checks), UVM_NONE)
        endfunction
    endclass

    class pwm_test extends uvm_test;
        `uvm_component_utils(pwm_test)
        pwm_env env;

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            env = pwm_env::type_id::create("env", this);
        endfunction

        task run_phase(uvm_phase phase);
            phase.raise_objection(this);
            // env의 run_phase와 test의 run_phase는 병렬 수행된다.
            // 이 장에서는 env의 완료를 기다리는 명시적 동기화가 필요하다.
            wait (env.done);
            phase.drop_objection(this);
        endtask
    endclass
endpackage

module tb_pwm_uvm;
    import uvm_pkg::*;
    import ch17_uvm_pkg::*;

    logic clk = 0;
    always #5 clk = ~clk;
    pwm_if bus(clk);

    pwm_core #(.RESET_PERIOD(8)) dut (
        .clk(clk), .resetn(bus.resetn), .cfg_apply(bus.cfg_apply),
        .cfg_period(bus.cfg_period), .cfg_duty(bus.cfg_duty),
        .cfg_enable(bus.cfg_enable), .cfg_polarity(bus.cfg_polarity),
        .pwm_out(bus.pwm_out), .pending(bus.pending),
        .active_period(bus.active_period), .active_duty(bus.active_duty),
        .active_enable(bus.active_enable),
        .active_polarity(bus.active_polarity)
    );

    initial begin
        // (추가) NO_VIF는 연결 실패를 검출하는 부정 시험 전용이다.
        if (!$test$plusargs("NO_VIF"))
            uvm_config_db#(virtual pwm_if)::set(null, "uvm_test_top.env", "vif", bus);
        run_test("pwm_test");
    end
    initial begin
        #2000;
        $fatal(1, "FAIL CH17 GLOBAL_TIMEOUT");
    end
endmodule
