#!/usr/bin/env bash
# 제19장: 실제 UVM 라이브러리·시뮬레이터가 있는 환경에서 실행한다.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DUT_PATH="${DUT_PATH:-$ROOT/reference_rtl/pwm_core.v}"
TB_PATH="$ROOT/tb/ch19/tb_pwm_monitor_agent_scoreboard.sv"
OUT="$ROOT/.build/ch19"

if [[ ! -f "$DUT_PATH" ]]; then
  echo "NOT_RUN: PWM DUT not found: $DUT_PATH" >&2
  exit 2
fi
if ! command -v verilator >/dev/null 2>&1; then
  echo "NOT_RUN: Verilator not installed" >&2
  exit 2
fi
if [[ -z "${UVM_HOME:-}" || ! -f "$UVM_HOME/src/uvm_pkg.sv" ]]; then
  echo "NOT_RUN: UVM_HOME/src/uvm_pkg.sv missing" >&2
  exit 2
fi

mkdir -p "$OUT"
verilator --version | tee "$OUT/tool_version.txt"

# --timing: 시간·이벤트 제어; --assert: 런타임 검증 활성화.
# UVM 호환성은 Verilator 버전과 사용하는 UVM 라이브러리에 따라 달라진다.
verilator --binary --timing --assert --trace -Wno-fatal \
  --top-module tb_pwm_monitor_agent_scoreboard \
  --Mdir "$OUT/obj_dir" \
  +incdir+"$UVM_HOME/src" \
  "$UVM_HOME/src/uvm_pkg.sv" "$DUT_PATH" "$TB_PATH" \
  2>&1 | tee "$OUT/build.log"

(cd "$OUT" && ./obj_dir/Vtb_pwm_monitor_agent_scoreboard \
  +UVM_TESTNAME=pwm19_test | tee simulation.log)

# 단순 종료 코드 외에 Scoreboard 완료 기록도 반드시 확인한다.
grep -q 'PASS CH19 requests=3 applied=3' "$OUT/simulation.log" || {
  echo "FAIL: Monitor 또는 Scoreboard 검증이 완료되지 않음" >&2
  exit 1
}
if grep -Eq 'UVM_(FATAL|ERROR)[[:space:]:]' "$OUT/simulation.log"; then
  echo "FAIL: UVM 오류 메시지 확인" >&2
  exit 1
fi
echo "PASS CH19 SUITE: 3 requests and 3 applied observations"
