#!/usr/bin/env bash
# CH22: AXI4-Lite Agent + IRQ/Reset Agent + Virtual Sequence UVM 실행.
# 상용 AXI VIP가 아니라 교육용 VIP-style AXI BFM과 독립 Monitor를 사용한다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL="${RTL_DIR:-$ROOT/reference_rtl}"
TB="$ROOT/tb/ch22/tb_axi_multiagent_irq.sv"
OUT="$ROOT/.build/ch22"

for p in "$RTL/axi4lite_slave_adapter.v" \
         "$RTL/custom_register_bank.v" "$TB"; do
  if [[ ! -f "$p" ]]; then
    echo "NOT_RUN: source file not found: $p" >&2
    exit 2
  fi
done
if ! command -v verilator >/dev/null 2>&1; then
  echo "NOT_RUN: Verilator is not installed" >&2
  exit 2
fi
if [[ -z "${UVM_HOME:-}" || ! -f "$UVM_HOME/src/uvm_pkg.sv" ]]; then
  echo "NOT_RUN: compatible UVM_HOME/src/uvm_pkg.sv is required" >&2
  exit 2
fi

mkdir -p "$OUT"
verilator --version | tee "$OUT/tool_version.txt"

# --timing: UVM 이벤트와 지연; --trace: VCD 기록; --assert: 검사.
# 실제 UVM 호환성은 설치된 Verilator/UVM 버전으로 확인해야 한다.
verilator --binary --timing --assert --trace -Wno-fatal \
  --top-module tb_axi_multiagent_irq --Mdir "$OUT/obj_dir" \
  +incdir+"$UVM_HOME/src" \
  "$UVM_HOME/src/uvm_pkg.sv" \
  "$RTL/axi4lite_slave_adapter.v" \
  "$RTL/custom_register_bank.v" "$TB" \
  2>&1 | tee "$OUT/build.log"

(cd "$OUT" && ./obj_dir/Vtb_axi_multiagent_irq \
  +UVM_TESTNAME=axi22_test | tee simulation.log)

# UVM 결과 문구와 실제 에러 수(0)를 독립적으로 확인한다.
if ! grep -q 'PASS CH22 AXI_W=4 AXI_R=11 IRQ=2 RESET=2' "$OUT/simulation.log"; then
  echo "FAIL: multi-agent scoreboard did not complete all checks" >&2
  exit 1
fi
# UVM_ERROR : 0 / UVM_FATAL : 0은 정상 요약이다.
if grep -Eq 'UVM_(ERROR|FATAL) @[[:space:]]*[0-9]+|UVM_(ERROR|FATAL)[[:space:]]*:[[:space:]]*[1-9]' "$OUT/simulation.log"; then
  echo "FAIL: UVM_ERROR or UVM_FATAL detected" >&2
  exit 1
fi
echo "PASS CH22 SUITE: 4 writes, 11 reads, 2 IRQ events, 2 resets"
echo "Logs: $OUT/build.log and $OUT/simulation.log"
echo "Waveform (if generated): $OUT/ch22_multiagent_axi_irq.vcd"
