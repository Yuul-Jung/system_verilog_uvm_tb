#!/usr/bin/env bash
# 제03장: 기존 pwm_core와 반복 자극 TB를 컴파일하고 시뮬레이션한다.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COURSE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DUT_PATH="${DUT_PATH:-$COURSE_ROOT/reference_rtl/pwm_core.v}"
TB_PATH="$COURSE_ROOT/tb/ch03/tb_pwm_reusable_stimulus.sv"
OUT_DIR="$COURSE_ROOT/.build/ch03"

# 컴파일러·실행기를 반드시 함께 확인한다.
for tool in iverilog vvp; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: $tool 명령이 없습니다. sudo apt install iverilog"
    exit 2
  fi
done

# DUT가 없으면 파일을 복사하지 말고 경로를 먼저 확인한다.
if [[ ! -f "$DUT_PATH" ]]; then
  echo "ERROR: 원본 RTL 없음: $DUT_PATH"
  echo "사용법: DUT_PATH=/실제/경로/pwm_core.v bash scripts/run_ch03.sh"
  exit 2
fi

mkdir -p "$OUT_DIR"

# -g2012는 이 테스트벤치의 SystemVerilog 문법을 지원하기 위한 옵션이다.
iverilog -g2012 -s tb_pwm_reusable_stimulus \
  -o "$OUT_DIR/simulation.vvp" "$DUT_PATH" "$TB_PATH"

# 표준 출력과 VCD 파형을 이 장만의 출력 폴더에 보존한다.
(cd "$OUT_DIR" && vvp simulation.vvp | tee output.log)
echo "로그: $OUT_DIR/output.log"
echo "파형: $OUT_DIR/ch03_pwm_reusable_stimulus.vcd"
