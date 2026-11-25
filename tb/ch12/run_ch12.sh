#!/usr/bin/env bash
# 제12장: 독립 PWM 원본 + XSIM 기능 커버리지 시험.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RTL="${1:-$ROOT/reference_rtl/pwm_core.v}"
if [[ ! -f "$RTL" ]]; then
  echo "FAIL: pwm_core.v 파일 없음" >&2
  exit 1
fi
RTL="$(realpath "$RTL")"
for tool in xvlog xelab xsim; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "NOT_RUN: $tool 없음. Vivado 환경을 설정하세요." >&2
    exit 2
  fi
done
mkdir -p "$ROOT/.build/ch12"
OUT="$(mktemp -d "$ROOT/.build/ch12/run.XXXXXX")"
cd "$OUT"
xvlog "$RTL" 2>&1 | tee rtl.log
xvlog -sv "$ROOT/tb/ch12/tb_pwm_coverage.sv" 2>&1 | tee tb.log
xelab -debug typical -cov_db_dir . -cov_db_name ch12_cov \
  tb_pwm_coverage -s ch12_sim 2>&1 | tee elaborate.log
xsim ch12_sim -runall -cov_db_dir . -cov_db_name ch12_cov \
  2>&1 | tee output.log
grep -Eq '^PASS CH12 cases=12 coverage=100\.00%[[:space:]]*$' output.log
if command -v xcrg >/dev/null 2>&1; then
  xcrg -dir . -db_name ch12_cov -report_dir report -report_format html
else
  echo "NOT_RUN: xcrg 보고서 생성 도구 없음"
fi
echo "실행 폴더: $OUT"
