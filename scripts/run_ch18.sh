#!/usr/bin/env bash
# 사용: UVM_HOME=/path/to/uvm bash scripts/run_ch18.sh
# 원본 PWM RTL은 읽기 전용이며 실행 파일·로그는 .build/ch18에 저장.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL="${DUT_PATH:-$ROOT/reference_rtl/pwm_core.v}"
if [[ ! -f "$RTL" ]]; then
  echo "NOT_RUN: PWM DUT missing: $RTL" >&2
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
mkdir -p "$ROOT/.build/ch18"
verilator --binary --timing --assert -Wno-fatal \
  --top-module tb_pwm_sequence_driver \
  --Mdir "$ROOT/.build/ch18/obj_dir" \
  +incdir+"$UVM_HOME/src" \
  "$UVM_HOME/src/uvm_pkg.sv" "$RTL" \
  "$ROOT/tb/ch18/tb_pwm_sequence_driver.sv"
"$ROOT/.build/ch18/obj_dir/Vtb_pwm_sequence_driver" \
  +UVM_TESTNAME=pwm18_test | tee "$ROOT/.build/ch18/simulation.log"
grep -q 'PASS CH18 checks=3' "$ROOT/.build/ch18/simulation.log"
