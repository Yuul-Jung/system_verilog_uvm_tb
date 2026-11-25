#!/usr/bin/env bash
# 제19장: Vivado XSIM 내장 UVM 라이브러리 사용.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL="${DUT_PATH:-$ROOT/reference_rtl/pwm_core.v}"
if [[ ! -f "$RTL" ]]; then
  echo "NOT_RUN: DUT missing" >&2
  exit 2
fi
RTL="$(realpath "$RTL")"
for tool in xvlog xelab xsim; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "NOT_RUN: $tool missing; source Vivado settings64.sh" >&2
    exit 2
  fi
done
mkdir -p "$ROOT/.build/ch19"
OUT="$(mktemp -d "$ROOT/.build/ch19/run.XXXXXX")"
cd "$OUT"
xvlog "$RTL" 2>&1 | tee rtl.log
xvlog -sv -L uvm "$ROOT/tb/ch19/tb_pwm_monitor_agent_scoreboard.sv" 2>&1 | tee tb.log
xelab -L uvm -debug typical tb_pwm_monitor_agent_scoreboard -s ch19_sim 2>&1 | tee elaborate.log
xsim ch19_sim -runall -onerror quit 2>&1 | tee normal.log
grep -Eq '\[RESULT\][[:space:]]+PASS CH19 requests=3 applied=3 samples=24[[:space:]]*$' normal.log
grep -Eq 'UVM_ERROR[[:space:]]*:[[:space:]]*0[[:space:]]*$' normal.log
grep -Eq 'UVM_FATAL[[:space:]]*:[[:space:]]*0[[:space:]]*$' normal.log
# 부정 시험: 126ns의 관찰 객체 PWM을 반전하여 Scoreboard를 시험한다.
# UVM $finish에 따른 종료 코드 차이가 있으므로 전용 진단도 검사한다.
rc=0
xsim ch19_sim -runall -onerror quit -testplusarg CORRUPT_SAMPLE > negative.log 2>&1 || rc=$?
grep -Eq 'UVM_FATAL.*\[SB_PWM\].*t=126 phase=2 expected=0 got=1' negative.log
if grep -q 'PASS CH19\|FAIL CH19 GLOBAL_TIMEOUT' negative.log; then
  echo "FAIL: unexpected negative result" >&2
  exit 1
fi
echo "PASS CH19 HARNESS (negative exit=$rc)"
echo "Logs: $OUT"
