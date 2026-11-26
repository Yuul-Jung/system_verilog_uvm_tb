`timescale 1ns/1ps
// 제11장: 기존 pwm_core 공개 포트에 SVA 시간 계약을 적용한다.
// SVA를 지원하는 SystemVerilog 시뮬레이터에서만 실행한다.
module tb_pwm_sva;
  logic clk = 0, resetn = 0, cfg_apply = 0;
  logic [31:0] cfg_period = 8, cfg_duty = 0;
  logic cfg_enable = 1, cfg_polarity = 0;
  wire pwm_out, pending, active_enable, active_polarity;
  wire [31:0] active_period, active_duty;
  integer checks = 0;
  // (추가) 어설션 관찰 경로의 의도된 실패 시험. DUT는 수정하지 않는다.
  bit inject_sva_pending = 0;
  // (추가) 속성의 선행 조건 발생 횟수. SVA 엔진의 통과 횟수와 구별한다.
  integer reset_hits = 0, disabled_hits = 0, apply_hits = 0;
  integer zero_hits = 0, full_hits = 0;
  // (추가) enable=0이면서 duty>0인 표본. enable 차단이 빠지면 출력이
  // HIGH가 되는 구간이므로 ap_disabled_low가 결함을 구별할 수 있다.
  integer disabled_duty_hits = 0;

  pwm_core #(.RESET_PERIOD(32'd8)) dut (
    .clk(clk), .resetn(resetn), .cfg_apply(cfg_apply),
    .cfg_period(cfg_period), .cfg_duty(cfg_duty),
    .cfg_enable(cfg_enable), .cfg_polarity(cfg_polarity),
    .pwm_out(pwm_out), .pending(pending),
    .active_period(active_period), .active_duty(active_duty),
    .active_enable(active_enable), .active_polarity(active_polarity)
  );
  always #5 clk = ~clk;

  // 리셋 중 출력은 LOW. 조합 차단은 별도 즉시 검사로 보강한다.
  ap_reset_low: assert property (
    @(posedge clk) !resetn |-> !pwm_out
  ) else $fatal(1, "FAIL SVA reset output");

  // Enable=0이면 극성과 무관하게 출력은 LOW.
  ap_disabled_low: assert property (
    @(posedge clk) disable iff (!resetn)
      !active_enable |-> !pwm_out
  ) else $fatal(1, "FAIL SVA disabled output");

  // cfg_apply는 상승 에지에 캡처되고 pending은 다음 샘플에 1.
  // 경계와 겹쳐도 cfg_apply 대입이 마지막이므로 pending=1.
  ap_apply_pending: assert property (
    @(posedge clk) disable iff (!resetn)
      cfg_apply |=> (pending && !inject_sva_pending)
  ) else begin
    // (추가) 실제 샘플 pending이 1인데 관찰 경로만 차단했을 때의 진단.
    if (inject_sva_pending && ($sampled(pending) === 1'b1))
      $fatal(1, "DETECTED_SVA_PENDING t=%0d", $time);
    else
      $fatal(1, "FAIL SVA apply pending");
  end

  // 주기·듀티가 8/0이고 정상 극성이면 출력은 LOW.
  ap_zero_duty: assert property (
    @(posedge clk) disable iff (!resetn)
      (active_enable && !active_polarity &&
       active_duty == 32'd0) |-> !pwm_out
  ) else $fatal(1, "FAIL SVA zero duty");

  // 8/8의 100% 듀티는 정상 극성에서 HIGH.
  ap_full_duty: assert property (
    @(posedge clk) disable iff (!resetn)
      (active_enable && !active_polarity &&
       active_period == 32'd8 &&
       active_duty == 32'd8) |-> pwm_out
  ) else $fatal(1, "FAIL SVA full duty");

  // (추가) 상승 에지 직전 상태를 읽는 선행 조건 집계.
  // TB 자극은 하강 에지, DUT 상태 갱신은 NBA에서 수행한다.
  always @(posedge clk) begin
    if (!resetn)
      reset_hits++;
    else begin
      if ((^{pwm_out, pending, active_period, active_duty,
             active_enable, active_polarity}) === 1'bx)
        $fatal(1, "FAIL UNKNOWN_OUTPUT");
      if (!active_enable) disabled_hits++;
      if (!active_enable && !active_polarity && active_duty != 32'd0)
        disabled_duty_hits++;
      if (cfg_apply) apply_hits++;
      if (active_enable && !active_polarity &&
          active_duty == 32'd0) zero_hits++;
      if (active_enable && !active_polarity &&
          active_period == 32'd8 && active_duty == 32'd8)
        full_hits++;
    end
  end

  task automatic apply_duty(input logic [31:0] duty);
    @(negedge clk);
    cfg_duty = duty;
    cfg_apply = 1;
    @(negedge clk);
    cfg_apply = 0;
    repeat (12) @(negedge clk);
    if (active_duty !== duty || pending !== 1'b0)
      $fatal(1, "FAIL APPLY duty=%0d actual=%0d pending=%b",
             duty, active_duty, pending);
    checks++;
  endtask

  initial begin
    #2000;
    $fatal(1, "FAIL GLOBAL_TIMEOUT");
  end
  initial begin
    inject_sva_pending = $test$plusargs("INJECT_SVA_PENDING");
`ifdef VCD
    $dumpfile("ch11_pwm_sva.vcd");
    $dumpvars(0, tb_pwm_sva);
`endif
    repeat (3) @(negedge clk);
    resetn = 1;
    apply_duty(32'd0);
    apply_duty(32'd8);
    apply_duty(32'd4);
    // 클록 사이에서 LOW 리셋을 걸면 PWM 출력은 즉시 차단된다.
    @(negedge clk);
    // (추가) 정상 HIGH 상태에서 리셋을 인가해야 출력 차단을 시험할 수 있다.
    if (pwm_out !== 1'b1)
      $fatal(1, "FAIL RESET_PRECONDITION");
    resetn = 0;
    #1;
    if (pwm_out !== 1'b0)
      $fatal(1, "FAIL RESET_GATE");
    repeat (2) @(negedge clk);
    resetn = 1;
    apply_duty(32'd2);
    // (추가) enable=0, duty=4를 적용한다. 정상 DUT의 출력은 LOW를 유지한다.
    @(negedge clk);
    cfg_enable = 0;
    cfg_duty = 32'd4;
    cfg_apply = 1;
    @(negedge clk);
    cfg_apply = 0;
    repeat (12) @(negedge clk);
    if (active_enable !== 1'b0 || active_duty !== 32'd4 || pending !== 1'b0)
      $fatal(1, "FAIL DISABLE_APPLY");
    // (추가) 선행 조건 미발생으로 인한 공허한 통과를 방지한다.
    if (checks != 4 || apply_hits != 5 || reset_hits == 0 ||
        disabled_hits == 0 || disabled_duty_hits == 0 ||
        zero_hits == 0 || full_hits == 0)
      $fatal(1, "FAIL SVA ACTIVATION");
    $display("ACTIVATION reset=%0d disabled=%0d disabled_duty=%0d apply=%0d zero=%0d full=%0d",
             reset_hits, disabled_hits, disabled_duty_hits, apply_hits,
             zero_hits, full_hits);
    $display("PASS CH11 SVA checks=%0d", checks);
    $finish;
  end
endmodule
