#!/usr/bin/env bash
# 제20장: Vivado XSIM 내장 UVM 라이브러리 사용.
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
mkdir -p "$ROOT/.build/ch20"
OUT="$(mktemp -d "$ROOT/.build/ch20/run.XXXXXX")"
cd "$OUT"
xvlog "$RTL" 2>&1 | tee rtl.log
xvlog -sv -L uvm "$ROOT/tb/ch20/tb_pwm_factory_config_objection.sv" 2>&1 | tee tb.log
xelab -timescale 1ns/1ps -L uvm -debug typical tb_pwm_factory_config_objection -s ch20_sim 2>&1 | tee elaborate.log
# 정상 시험 두 가지: 동일 환경에서 설정만 변경한다.
check_normal() {
  local log="$1" plan="$2" a="$3" b="$4" c="$5"
  grep -Eq "\[RESULT\][[:space:]]+PASS CH20 factory=traced plan=$plan applied=3 samples=24[[:space:]]*$" "$log"
  grep -Eq 'UVM_ERROR[[:space:]]*:[[:space:]]*0[[:space:]]*$' "$log"
  grep -Eq 'UVM_FATAL[[:space:]]*:[[:space:]]*0[[:space:]]*$' "$log"
  for duty in "$a" "$b" "$c"; do
    grep -Eq "\[FACTORY_TRACE\][[:space:]]+DRIVE duty=$duty[[:space:]]*$" "$log"
  done
  [[ "$(grep -Ec '\[FACTORY_TRACE\][[:space:]]+DRIVE duty=' "$log")" -eq 3 ]]
}
xsim ch20_sim -runall -onerror quit 2>&1 | tee normal.log
check_normal normal.log 2,6,0 2 6 0
xsim ch20_sim -runall -onerror quit -testplusarg ALT_PLAN 2>&1 | tee alt.log
check_normal alt.log 1,8,3 1 8 3

# 부정 시험: 각 실행에서 하나의 구성 조건만 제거한다.
check_negative() {
  local arg="$1" pattern="$2" rc=0
  xsim ch20_sim -runall -onerror quit -testplusarg "$arg" > "$arg.log" 2>&1 || rc=$?
  grep -Eq "$pattern" "$arg.log"
  if grep -Eq 'PASS CH20|FAIL CH20 GLOBAL_TIMEOUT' "$arg.log"; then
    echo "FAIL: unexpected negative result ($arg)" >&2
    exit 1
  fi
  echo "DETECTED $arg (xsim exit=$rc)"
}
check_negative NO_OVERRIDE 'UVM_FATAL.*\[FACTORY\].*Driver type override was ignored'
check_negative NO_CFG 'UVM_FATAL.*\[NO_CFG\].*Driver config not found'
check_negative EARLY_DROP 'UVM_FATAL.*\[COUNTS\].*Incomplete verification samples=17'
echo "PASS CH20 HARNESS normal=2 negative=3"
echo "Logs: $OUT"
