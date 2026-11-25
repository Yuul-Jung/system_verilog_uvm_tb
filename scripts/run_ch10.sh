#!/usr/bin/env bash
# 제10장: 정상 경계값 시험 + 오류 주입 2건(예상 실패)을 자동 확인한다.
# 오류 주입은 테스트벤치의 관찰 경로/입력 요청에만 적용한다. DUT 수정 없음.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DUT_PATH="${DUT_PATH:-$ROOT/reference_rtl/pwm_core.v}"
TB_PATH="$ROOT/tb/ch10/tb_pwm_corner_reset_timeout.sv"
OUT="$ROOT/.build/ch10"

for tool in iverilog vvp; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "NOT_RUN: $tool 미설치. sudo apt update && sudo apt install iverilog" >&2
    exit 2
  fi
done
if [[ ! -f "$DUT_PATH" ]]; then
  echo "FAIL: 원본 DUT 파일 없음: $DUT_PATH" >&2
  exit 1
fi

mkdir -p "$OUT"
# 이전 실행의 파형을 이번 실행 결과로 오인하지 않도록 정리한다.
rm -f "$OUT/ch10_pwm_corner_reset_timeout.vcd" "$OUT/normal.vcd" \
  "$OUT/fault_injection.vcd" "$OUT/apply_timeout.vcd"
iverilog -g2012 -DVCD -s tb_pwm_corner_reset_timeout -o "$OUT/sim.vvp" \
  "$DUT_PATH" "$TB_PATH" 2>&1 | tee "$OUT/build.log"

# ① 정상 사례: 실제 DUT가 0%·100%·중간 리셋·재설정을 통과해야 함.
(cd "$OUT" && vvp ./sim.vvp | tee normal.log)
if [[ -f "$OUT/ch10_pwm_corner_reset_timeout.vcd" ]]; then
  mv "$OUT/ch10_pwm_corner_reset_timeout.vcd" "$OUT/normal.vcd"
fi
if ! grep -q '^PASS CH10 requests=3 checks=48$' "$OUT/normal.log"; then
  echo "FAIL: 정상 시험이 기대한 48회 검사를 완료하지 못함" >&2
  exit 1
fi

# ② 부정 시험: 관찰 경로의 PWM 값만 반전한다.
# 반드시 비정상 종료 + 전용 진단 문자열을 동시에 확인해야 통과.
if (cd "$OUT" && vvp ./sim.vvp +INJECT_FAULT >fault_injection.log 2>&1); then
  echo "FAIL: 주입한 PWM 관찰 오류를 검출하지 못함" >&2
  exit 1
fi
if [[ -f "$OUT/ch10_pwm_corner_reset_timeout.vcd" ]]; then
  mv "$OUT/ch10_pwm_corner_reset_timeout.vcd" "$OUT/fault_injection.vcd"
fi
grep -q 'DETECTED_INJECTED_FAULT' "$OUT/fault_injection.log" || {
  echo "FAIL: PWM 관찰 오류 대신 다른 이유로 실패함" >&2
  exit 1
}
echo "PASS HARNESS: 의도한 PWM 관찰 오류 검출"

# ③ 부정 시험: 듀티 8의 cfg_apply를 누락하여 적용 타임아웃을 검사한다.
if (cd "$OUT" && vvp ./sim.vvp +INJECT_TIMEOUT >apply_timeout.log 2>&1); then
  echo "FAIL: 누락한 cfg_apply를 타임아웃으로 검출하지 못함" >&2
  exit 1
fi
if [[ -f "$OUT/ch10_pwm_corner_reset_timeout.vcd" ]]; then
  mv "$OUT/ch10_pwm_corner_reset_timeout.vcd" "$OUT/apply_timeout.vcd"
fi
grep -q 'DETECTED_APPLY_TIMEOUT' "$OUT/apply_timeout.log" || {
  echo "FAIL: 적용 타임아웃 대신 다른 이유로 실패함" >&2
  exit 1
}
echo "PASS HARNESS: 의도한 cfg_apply 누락 타임아웃 검출"

echo "PASS CH10 SUITE: 정상 1회 + 의도된 오류 검출 2회"
echo "로그: $OUT/{normal,fault_injection,apply_timeout}.log"
