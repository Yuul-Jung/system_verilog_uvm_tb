#!/usr/bin/env bash
# 제01장 실행: 원본 RTL은 수정하지 않고 테스트벤치만 컴파일한다.
set -euo pipefail

# 이 스크립트가 어느 경로에서 실행되어도 과정 폴더를 찾는다.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COURSE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# amd_soc_rtl 저장소 안의 과정 폴더를 기준으로 원본 RTL 경로를 지정한다.
# 별도 저장소로 이동한 경우에는 DUT_PATH 환경변수로 경로를 넘긴다.
DUT_PATH="${DUT_PATH:-$COURSE_ROOT/reference_rtl/uart_echo_controller.v}"
TB_PATH="$COURSE_ROOT/tb/ch01/tb_uart_echo_basics.sv"
OUT_DIR="$COURSE_ROOT/.build/ch01"

if ! command -v iverilog >/dev/null 2>&1; then
  echo "ERROR: iverilog 명령을 찾을 수 없습니다. sudo apt install iverilog"
  exit 2
fi
if ! command -v vvp >/dev/null 2>&1; then
  echo "ERROR: vvp 명령을 찾을 수 없습니다. Icarus Verilog 설치를 확인하세요."
  exit 2
fi
if [[ ! -f "$DUT_PATH" ]]; then
  echo "ERROR: 원본 RTL 파일 없음: $DUT_PATH"
  echo "예: DUT_PATH=/절대경로/uart_echo_controller.v bash scripts/run_ch01.sh"
  exit 2
fi

mkdir -p "$OUT_DIR"
# -g2012: SystemVerilog 2012 문법, -DVCD: 파형 기록 기능 활성화.
iverilog -g2012 -DVCD -s tb_uart_echo_basics \
  -o "$OUT_DIR/tb.out" "$DUT_PATH" "$TB_PATH"

# VCD 파일과 로그를 실행 폴더에 기록한다.
(cd "$OUT_DIR" && vvp ./tb.out | tee output.log)
echo "파형 파일: $OUT_DIR/ch01_uart_echo.vcd"
