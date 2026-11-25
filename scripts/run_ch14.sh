#!/usr/bin/env bash
# 제14장: 원본 uart_core + uart_rx + uart_tx와 TB 컴파일 및 실행.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL="${RTL_DIR:-$ROOT/reference_rtl}"
if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
  echo "NOT_RUN: iverilog 또는 vvp 없음" >&2
  exit 2
fi
for file in uart_core.v uart_rx.v uart_tx.v; do
  if [[ ! -f "$RTL/$file" ]]; then
    echo "NOT_RUN: 원본 RTL 없음: $RTL/$file" >&2
    exit 2
  fi
done
RTL="$(realpath "$RTL")"
mkdir -p "$ROOT/.build/ch14"
cd "$ROOT/.build/ch14"
iverilog -g2012 -DVCD -s tb_uart_fifo_flow -o sim \
  "$RTL/uart_core.v" "$RTL/uart_rx.v" "$RTL/uart_tx.v" \
  "$ROOT/tb/ch14/tb_uart_fifo_flow.sv"
vvp sim | tee simulation.log
grep -Fxq 'PASS CH14 tx=18 rx=16+17 overrun=1 reset=1' simulation.log
