#!/usr/bin/env bash
# 제05장: SystemVerilog 자료형 실습과 기존 UART Echo 조합 DUT 실행.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DUT_PATH="${DUT_PATH:-$ROOT/reference_rtl/uart_echo_controller.v}"
TB_PATH="$ROOT/tb/ch05/tb_uart_types.sv"
OUT_DIR="$ROOT/.build/ch05"

for tool in iverilog vvp; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: $tool 명령 없음. sudo apt install iverilog"
    exit 2
  fi
done
if [[ ! -f "$DUT_PATH" ]]; then
  echo "ERROR: 원본 RTL 경로 없음: $DUT_PATH"
  echo "사용법: DUT_PATH=/경로/uart_echo_controller.v bash scripts/run_ch05.sh"
  exit 2
fi

mkdir -p "$OUT_DIR"
iverilog -g2012 -DVCD -s tb_uart_types -o "$OUT_DIR/simulation.vvp" \
  "$DUT_PATH" "$TB_PATH"
(cd "$OUT_DIR" && vvp simulation.vvp | tee output.log)
grep -Fxq 'PASS checks=6 failures=0' "$OUT_DIR/output.log"
echo "로그: $OUT_DIR/output.log"
echo "파형: $OUT_DIR/ch05_uart_types.vcd"
