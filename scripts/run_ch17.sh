#!/usr/bin/env bash
# 제17장: UVM 라이브러리가 설치된 Verilator 5.x에서 실행.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL="${DUT_PATH:-$ROOT/reference_rtl/pwm_core.v}"
if [[ ! -f "$RTL" ]]; then
  echo "NOT_RUN: DUT missing: $RTL" >&2
  exit 2
fi
if ! command -v verilator >/dev/null 2>&1; then
  echo "NOT_RUN: Verilator not installed" >&2
  exit 2
fi
if [[ -z "${UVM_HOME:-}" || ! -f "$UVM_HOME/src/uvm_pkg.sv" ]]; then
  echo "NOT_RUN: UVM_HOME/src/uvm_pkg.sv not found" >&2
  exit 2
fi
mkdir -p "$ROOT/.build/ch17"
verilator --binary --timing --assert -Wno-fatal \
  --top-module tb_pwm_uvm \
  --Mdir "$ROOT/.build/ch17/obj_dir" \
  +incdir+"$UVM_HOME/src" \
  "$UVM_HOME/src/uvm_pkg.sv" "$RTL" \
  "$ROOT/tb/ch17/tb_pwm_uvm.sv"
"$ROOT/.build/ch17/obj_dir/Vtb_pwm_uvm" \
  +UVM_TESTNAME=pwm_test | tee "$ROOT/.build/ch17/simulation.log"
grep -q 'PASS CH17 checks=1' "$ROOT/.build/ch17/simulation.log"
