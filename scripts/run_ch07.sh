#!/usr/bin/env bash
# 제07장: interface/modport/clocking block이 포함된 SystemVerilog 시뮬레이션.
# iverilog는 clocking block 지원이 제한적이므로 이 장은 Verilator 사용.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COURSE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DUT_PATH="${DUT_PATH:-$COURSE_ROOT/reference_rtl/uart_echo_controller.v}"
IF_PATH="$COURSE_ROOT/tb/ch07/uart_stream_if.sv"
TB_PATH="$COURSE_ROOT/tb/ch07/tb_uart_interface.sv"
OUT_DIR="$COURSE_ROOT/.build/ch07"

# 도구 버전과 DUT 경로를 먼저 확인해 모호한 실패를 방지한다.
if ! command -v verilator >/dev/null 2>&1; then
  echo "ERROR: Verilator가 설치되지 않았습니다."
  echo "Ubuntu: sudo apt update && sudo apt install verilator g++ make"
  exit 2
fi
if [[ ! -f "$DUT_PATH" ]]; then
  echo "ERROR: 기존 UART Echo RTL 파일 없음: $DUT_PATH"
  echo "DUT_PATH=/실제/경로/uart_echo_controller.v bash scripts/run_ch07.sh"
  exit 2
fi
mkdir -p "$OUT_DIR"
verilator --version | tee "$OUT_DIR/tool_version.txt"

# --timing: 이벤트·시간 제어를 활성화한다.
# --trace: VCD 파형 출력 기능을 활성화한다.
# 컴파일 오류가 나면 clocking 지원이 되는 Verilator 버전인지 확인한다.
verilator --binary --timing --trace --top-module tb_uart_interface \
  --Mdir "$OUT_DIR/obj_dir" \
  "$IF_PATH" "$DUT_PATH" "$TB_PATH" \
  2>&1 | tee "$OUT_DIR/build.log"

# pipefail을 사용하므로 DUT 검증 실패나 실행 실패를 성공으로 숨기지 않는다.
(cd "$OUT_DIR" && ./obj_dir/Vtb_uart_interface | tee output.log)
echo "실제 실행 로그: $OUT_DIR/output.log"
echo "실제 VCD 파형: $OUT_DIR/ch07_uart_interface.vcd"
