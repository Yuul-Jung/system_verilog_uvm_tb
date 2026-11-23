#!/usr/bin/env bash
# 사용: bash scripts/run_ch15.sh
# 원본 RTL은 읽기 전용; 시뮬레이션 산출물은 .build/ch15에만 생성한다.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL="${RTL_DIR:-$ROOT/reference_rtl}"
for f in axi4lite_slave_adapter.v custom_register_bank.v; do
  if [[ ! -f "$RTL/$f" ]]; then
    echo "NOT_RUN: missing $RTL/$f" >&2
    exit 2
  fi
done
if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
  echo "NOT_RUN: Icarus Verilog not installed" >&2
  exit 2
fi
mkdir -p "$ROOT/.build/ch15"
cd "$ROOT/.build/ch15"
iverilog -g2012 -s tb_axi4lite_registers -o sim \
  "$RTL/axi4lite_slave_adapter.v" "$RTL/custom_register_bank.v" \
  "$ROOT/tb/ch15/tb_axi4lite_registers.sv"
vvp sim | tee simulation.log
grep -q '^PASS CH15 commits=3 checks=10$' simulation.log
