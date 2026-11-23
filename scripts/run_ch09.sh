#!/usr/bin/env bash
# 제09장: PWM 원본, 독립 참조 모델, 스코어보드를 컴파일·실행한다.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DUT_PATH="${DUT_PATH:-$ROOT/reference_rtl/pwm_core.v}"
MODEL="$ROOT/tb/ch09/pwm_reference_model.sv"
TB="$ROOT/tb/ch09/tb_pwm_scoreboard.sv"
OUT="$ROOT/.build/ch09"

for tool in iverilog vvp; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: $tool 미설치. sudo apt update && sudo apt install iverilog"
    exit 2
  fi
done
if [[ ! -f "$DUT_PATH" ]]; then
  echo "ERROR: 원본 PWM 파일 없음: $DUT_PATH"
  exit 2
fi

mkdir -p "$OUT"

# -g2012: SystemVerilog 문법 활성화. 실패한 빌드 로그도 확인한다.
iverilog -g2012 -s tb_pwm_scoreboard -o "$OUT/simulation.vvp" \
  "$DUT_PATH" "$MODEL" "$TB" 2>&1 | tee "$OUT/build.log"

# pipefail: 시뮬레이터에서 $fatal이 발생하면 실행 실패로 전달된다.
(cd "$OUT" && vvp simulation.vvp | tee output.log)
echo "로그: $OUT/output.log"
echo "파형: $OUT/ch09_pwm_scoreboard.vcd"
