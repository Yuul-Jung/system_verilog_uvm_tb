#!/usr/bin/env bash
# 제22장: Vivado XSIM 내장 UVM 라이브러리 사용.
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
mkdir -p "$ROOT/.build/ch22"
OUT="$(mktemp -d "$ROOT/.build/ch22/run.XXXXXX")"
cd "$OUT"
xvlog "$RTL/axi4lite_slave_adapter.v" "$RTL/custom_register_bank.v" 2>&1 | tee rtl.log
xvlog -sv -L uvm "$ROOT/tb/ch22/tb_axi_multiagent_irq.sv" 2>&1 | tee tb.log
xelab -L uvm -debug typical tb_axi_multiagent_irq -s ch22_sim 2>&1 | tee elaborate.log
xsim ch22_sim -runall -onerror quit 2>&1 | tee normal.log
grep -Eq '\[RESULT\][[:space:]]+PASS CH22 AXI_W=6 AXI_R=13 IRQ=4 RESET=2 COLLISION=1 ZERO=1[[:space:]]*$' normal.log
grep -Eq 'UVM_ERROR[[:space:]]*:[[:space:]]*0[[:space:]]*$' normal.log
grep -Eq 'UVM_FATAL[[:space:]]*:[[:space:]]*0[[:space:]]*$' normal.log
rc=0
xsim ch22_sim -runall -onerror quit -testplusarg CORRUPT_IRQ > negative.log 2>&1 || rc=$?
grep -Eq 'UVM_FATAL.*\[IRQ_MISMATCH\].*status=10 expected=11 collisions=1' negative.log
if grep -Eq 'PASS CH22|CH22 GLOBAL_TIMEOUT' negative.log; then
  echo "FAIL: unexpected negative result" >&2
  exit 1
fi
echo "PASS CH22 HARNESS (negative exit=$rc)"
echo "Logs: $OUT"
