#!/usr/bin/env bash
# CH21: UVM RAL frontdoor simulation; no changes to source RTL.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL="${RTL_DIR:-$ROOT/reference_rtl}"
OUT="$ROOT/.build/ch21"
for f in axi4lite_slave_adapter.v custom_register_bank.v; do
  if [[ ! -f "$RTL/$f" ]]; then echo "NOT_RUN: missing $RTL/$f" >&2; exit 2; fi
done
if ! command -v verilator >/dev/null 2>&1; then
  echo "NOT_RUN: Verilator unavailable" >&2; exit 2
fi
if [[ -z "${UVM_HOME:-}" || ! -f "$UVM_HOME/src/uvm_pkg.sv" ]]; then
  echo "NOT_RUN: UVM_HOME/src/uvm_pkg.sv unavailable" >&2; exit 2
fi
mkdir -p "$OUT"
verilator --version > "$OUT/verilator_version.txt"
verilator --binary --timing --assert -Wno-fatal \
  --top-module tb_axi_uvm_ral --Mdir "$OUT/obj_dir" \
  +incdir+"$UVM_HOME/src" "$UVM_HOME/src/uvm_pkg.sv" \
  "$RTL/axi4lite_slave_adapter.v" "$RTL/custom_register_bank.v" \
  "$ROOT/tb/ch21/tb_axi_uvm_ral.sv" 2>&1 | tee "$OUT/build.log"
(cd "$OUT" && ./obj_dir/Vtb_axi_uvm_ral +UVM_TESTNAME=axi21_test | tee simulation.log)
grep -q 'PASS CH21 RAL frontdoor reads=4 writes=2' "$OUT/simulation.log"
if grep -Eq 'UVM_(ERROR|FATAL)' "$OUT/simulation.log"; then
  echo "FAIL: UVM ERROR/FATAL in log" >&2; exit 1
fi
echo "PASS CH21 SUITE"
