#!/usr/bin/env bash
# 제21장: Vivado XSIM 내장 UVM 라이브러리 사용.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL="${RTL_DIR:-$ROOT/reference_rtl}"
for f in axi4lite_slave_adapter.v custom_register_bank.v; do
  if [[ ! -f "$RTL/$f" ]]; then echo "NOT_RUN: missing $RTL/$f" >&2; exit 2; fi
done
RTL="$(realpath "$RTL")"
for tool in xvlog xelab xsim; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "NOT_RUN: $tool missing; source Vivado settings64.sh" >&2
    exit 2
  fi
done
mkdir -p "$ROOT/.build/ch21"
OUT="$(mktemp -d "$ROOT/.build/ch21/run.XXXXXX")"
cd "$OUT"
xvlog "$RTL/axi4lite_slave_adapter.v" "$RTL/custom_register_bank.v" 2>&1 | tee rtl.log
xvlog -sv -L uvm "$ROOT/tb/ch21/tb_axi_uvm_ral.sv" 2>&1 | tee tb.log
xelab -timescale 1ns/1ps -L uvm -debug typical tb_axi_uvm_ral -s ch21_sim 2>&1 | tee elaborate.log
xsim ch21_sim -runall -onerror quit 2>&1 | tee normal.log
grep -Eq '\[RESULT\][[:space:]]+PASS CH21 RAL reads=7 writes=3[[:space:]]*$' normal.log
grep -Eq 'UVM_ERROR[[:space:]]*:[[:space:]]*0[[:space:]]*$' normal.log
grep -Eq 'UVM_FATAL[[:space:]]*:[[:space:]]*0[[:space:]]*$' normal.log
rc=0
xsim ch21_sim -runall -onerror quit -testplusarg NO_PREDICT > negative.log 2>&1 || rc=$?
grep -Eq 'UVM_FATAL.*\[PREDICT_WRITE\].*addr=00000010 expected=11223344' negative.log
if grep -Eq 'PASS CH21|CH21 GLOBAL_TIMEOUT' negative.log; then
  echo "FAIL: unexpected negative result" >&2
  exit 1
fi
echo "PASS CH21 HARNESS (negative exit=$rc)"
echo "Logs: $OUT"
