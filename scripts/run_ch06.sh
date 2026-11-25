#!/usr/bin/env bash
# 제06장: 패키지를 DUT/TB보다 먼저 컴파일한다.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COURSE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DUT_PATH="${DUT_PATH:-$COURSE_ROOT/reference_rtl/uart_echo_controller.v}"
PKG_PATH="$COURSE_ROOT/tb/ch06/uart_expect_pkg.sv"
TB_PATH="$COURSE_ROOT/tb/ch06/tb_uart_arrays_queues.sv"
OUT_DIR="$COURSE_ROOT/.build/ch06"

for tool in iverilog vvp; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: $tool 명령이 없습니다. sudo apt install iverilog"
    exit 2
  fi
done

if [[ ! -f "$DUT_PATH" ]]; then
  echo "ERROR: 원본 DUT 파일 없음: $DUT_PATH"
  exit 2
fi

mkdir -p "$OUT_DIR"
# SystemVerilog 패키지를 먼저 지정해야 import가 해석된다.
iverilog -g2012 -DVCD -s tb_uart_arrays_queues \
  -o "$OUT_DIR/simulation.vvp" "$PKG_PATH" "$DUT_PATH" "$TB_PATH"

# pipefail로 시뮬레이터의 실패 종료 코드를 유지한다.
(cd "$OUT_DIR" && vvp simulation.vvp | tee output.log)
grep -q '^PASS checks=11 failures=0 queue=0echo "로그: $OUT_DIR/output.log"
echo "파형: $OUT_DIR/ch06_uart_arrays_queues.vcd"
 "$OUT_DIR/output.log"
echo "로그: $OUT_DIR/output.log"
echo "파형: $OUT_DIR/ch06_uart_arrays_queues.vcd"
