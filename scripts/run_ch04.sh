#!/usr/bin/env bash
# CH04: 기존 PWM RTL을 읽기 전용으로 참조하는 자동 검증.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COURSE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DUT_PATH="${DUT_PATH:-$COURSE_ROOT/reference_rtl/pwm_core.v}"
TB_PATH="$COURSE_ROOT/tb/ch04/tb_pwm_pass_fail.sv"
OUT_DIR="$COURSE_ROOT/.build/ch04"
for tool in iverilog vvp; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo "ERROR: $tool 없음. sudo apt install iverilog"; exit 2;
  }
done
[[ -f "$DUT_PATH" ]] || { echo "ERROR: DUT 파일 없음: $DUT_PATH"; exit 2; }
mkdir -p "$OUT_DIR"
iverilog -g2012 -s tb_pwm_pass_fail -o "$OUT_DIR/simulation.vvp" \
  "$DUT_PATH" "$TB_PATH"
(cd "$OUT_DIR" && vvp simulation.vvp | tee output.log)
echo "로그: $OUT_DIR/output.log"
echo "파형: $OUT_DIR/ch04_pwm_pass_fail.vcd"
