`timescale 1ns/1ps
// 제17장: 기존 pwm_core를 읽기 전용 DUT로 사용하는 최소 UVM 환경.
// UVM의 build/connect/run/check/report phase와 objection 수명주기를 확인한다.
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

        function new(string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            if (!uvm_config_db#(virtual pwm_if)::get(this, "", "vif", vif))
                `uvm_fatal("NOVIF", "pwm_if was not provided")
        endfunction

        // 출력이 바뀌는 에지 직후를 피하고 negedge에서 확인한다.
        task automatic expect_ports(
            input logic [31:0] duty, input logic enable,
            input logic expected_pwm
        );
            @(negedge vif.clk);
            if (vif.active_period !== 32'd8 ||
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
                vif.active_duty !== 0 ||
                vif.active_enable !== 0 || vif.pending !== 0)
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
            if (vif.pending !== 1'b1)
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

            // duty=4, period=8: 첫 네 클록 HIGH, 다음 네 클록 LOW.
            // 경계 직후 counter=0이므로 현재 출력은 HIGH이다.
            if (vif.pwm_out !== 1'b1)
                `uvm_fatal("PWM", "Expected HIGH at new period")
            // 4번의 상승 에지 후 counter=4, 출력은 LOW.
            repeat (4) @(negedge vif.clk);
            if (vif.pwm_out !== 1'b0)
                `uvm_fatal("PWM", "Expected LOW after duty window")
            checks++;
            `uvm_info("PWM", "PWM_DUTY_CHECKED", UVM_LOW)
        endtask

        function void check_phase(uvm_phase phase);
            super.check_phase(phase);
            if (checks != 1)
                `uvm_fatal("CHECK", $sformatf("checks=%0d", checks))
        endfunction

        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
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
            wait (env.checks == 1);
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
        uvm_config_db#(virtual pwm_if)::set(null, "*", "vif", bus);
        run_test("pwm_test");
    end
    initial begin
        #2000;
        $fatal(1, "FAIL CH17 GLOBAL_TIMEOUT");
    end
endmodule
