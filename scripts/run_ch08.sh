#!/usr/bin/env bash
# 제08장: 클래스/상속/제약 무작위 입력을 기존 UART Echo RTL에 적용한다.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DUT_PATH="${DUT_PATH:-$ROOT/reference_rtl/uart_echo_controller.v}"
TB_PATH="$ROOT/tb/ch08/tb_uart_objects.sv"
OUT="$ROOT/.build/ch08"
if ! command -v verilator >/dev/null 2>&1; then
  echo "ERROR: Verilator 미설치. Ubuntu: sudo apt update && sudo apt install verilator g++ make"
  exit 2
fi
if [[ ! -f "$DUT_PATH" ]]; then echo "ERROR: DUT 파일 없음: $DUT_PATH"; exit 2; fi
mkdir -p "$OUT"
verilator --version | tee "$OUT/tool_version.txt"
# 제약 무작위화를 지원하는 최신 Verilator와 외부 solver를 사용한다.
# 기본 solver인 z3가 필요하다(VERILATOR_SOLVER로 다른 solver 지정 가능).
if [[ -z "${VERILATOR_SOLVER:-}" ]] && ! command -v z3 >/dev/null 2>&1; then
  echo "ERROR: z3 없음. sudo apt install z3"; exit 2
fi
verilator --binary --timing --sv -Wno-TIMESCALEMOD --top-module tb_uart_objects \
  --Mdir "$OUT/obj_dir" "$DUT_PATH" "$TB_PATH" 2>&1 | tee "$OUT/build.log"
(cd "$OUT" && ./obj_dir/Vtb_uart_objects | tee output.log)
echo "실행 기록: $OUT/output.log"
