#!/usr/bin/env bash
# 제18장: Vivado XSIM 내장 UVM 라이브러리 사용.
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
mkdir -p "$ROOT/.build/ch18"
OUT="$(mktemp -d "$ROOT/.build/ch18/run.XXXXXX")"
cd "$OUT"
xvlog "$RTL" 2>&1 | tee rtl.log
xvlog -sv -L uvm "$ROOT/tb/ch18/tb_pwm_sequence_driver.sv" 2>&1 | tee tb.log
xelab -timescale 1ns/1ps -L uvm -debug typical tb_pwm_sequence_driver -s ch18_sim 2>&1 | tee elaborate.log
xsim ch18_sim -runall -onerror quit 2>&1 | tee normal.log
grep -Eq '\[RESULT\][[:space:]]+PASS CH18 checks=3 samples=24[[:space:]]*$' normal.log
grep -Eq 'UVM_ERROR[[:space:]]*:[[:space:]]*0[[:space:]]*$' normal.log
grep -Eq 'UVM_FATAL[[:space:]]*:[[:space:]]*0[[:space:]]*$' normal.log
# 부정 시험: 두 번째 거래의 직접 대입 범위 오류를 검출한다.
# UVM $finish에 따른 종료 코드 차이가 있으므로 전용 진단도 검사한다.
rc=0
xsim ch18_sim -runall -onerror quit -testplusarg INVALID_DUTY > negative.log 2>&1 || rc=$?
grep -Eq 'UVM_FATAL.*\[INVALID_DUTY\].*duty=9 completed=1' negative.log
if grep -q 'PASS CH18\|FAIL CH18 GLOBAL_TIMEOUT' negative.log; then
  echo "FAIL: unexpected negative result" >&2
  exit 1
fi
echo "PASS CH18 HARNESS (negative exit=$rc)"
echo "Logs: $OUT"
