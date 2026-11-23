#!/usr/bin/env bash
# 사용: bash scripts/run_ch13.sh
# Icarus Verilog로 원본 DUT를 읽기 전용 컴파일하고 결과는 .build/ch13에 저장.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DUT="${DUT_PATH:-$ROOT/reference_rtl/uart_echo_controller.v}"
TB="$ROOT/tb/ch13/tb_uart_stream.sv"
if [[ ! -f "$DUT" ]]; then echo "NOT_RUN: DUT 없음: $DUT" >&2; exit 2; fi
if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
  echo "NOT_RUN: iverilog/vvp 미설치" >&2; exit 2
fi
mkdir -p "$ROOT/.build/ch13"
cd "$ROOT/.build/ch13"
iverilog -g2012 -s tb_uart_stream -o sim "$DUT" "$TB"
vvp sim | tee simulation.log
grep -q '^PASS CH13 accepted=3 checks=11$' simulation.log
