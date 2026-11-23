#!/usr/bin/env bash
# 제02장: 기존 RTL을 수정하지 않고 테스트벤치·VCD·로그를 실행한다.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COURSE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 독립 저장소에 보관한 원본 스냅샷을 기본 사용한다.
# 독립 경로에 있다면 DUT_PATH 환경변수로 파일 위치를 지정한다.
DUT_PATH="${DUT_PATH:-$COURSE_ROOT/reference_rtl/pwm_core.v}"
TB_PATH="$COURSE_ROOT/tb/ch02/tb_pwm_clock_reset.sv"
OUT_DIR="$COURSE_ROOT/.build/ch02"

for tool in iverilog vvp; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: $tool 명령이 없습니다. sudo apt install iverilog"
    exit 2
  fi
done
if [[ ! -f "$DUT_PATH" ]]; then
  echo "ERROR: DUT 파일 없음: $DUT_PATH"
  echo "사용법: DUT_PATH=/실제/경로/pwm_core.v bash scripts/run_ch02.sh"
  exit 2
fi

mkdir -p "$OUT_DIR"

# SystemVerilog 문법과 원본 PWM 회로를 함께 컴파일한다.
iverilog -g2012 -s tb_pwm_clock_reset \
  -o "$OUT_DIR/simulation.vvp" "$DUT_PATH" "$TB_PATH"

# 실행 로그와 파형을 작업 폴더에 저장한다.
(cd "$OUT_DIR" && vvp simulation.vvp | tee output.log)
echo "로그: $OUT_DIR/output.log"
echo "파형: $OUT_DIR/ch02_pwm_clock_reset.vcd"
