#!/usr/bin/env bash
# 제11장: 독립 저장소의 원본 RTL과 SVA 테스트벤치를 XSIM으로 실행.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RTL="${1:-$ROOT/reference_rtl/pwm_core.v}"
TB="$ROOT/tb/ch11/tb_pwm_sva.sv"
OUT="$ROOT/.build/ch11/xsim"
if [[ ! -f "$RTL" || ! -f "$TB" ]]; then
  echo "FAIL: RTL 또는 TB 파일 없음" >&2
  exit 1
fi
# (변경) 상대 경로도 작업 폴더 이동 전에 절대 경로로 변환.
RTL="$(realpath "$RTL")"
for tool in xvlog xelab xsim; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "NOT_RUN: $tool 미설치 또는 Vivado 환경 미설정" >&2
    exit 2
  fi
done
mkdir -p "$OUT"
cd "$OUT"
xvlog "$RTL"
xvlog -sv "$TB"
xelab -debug typical tb_pwm_sva -s ch11_sim
xsim ch11_sim -runall 2>&1 | tee ch11.log
grep -q '^PASS CH11 SVA checks=4$' ch11.log
if grep -q 'FAIL SVA\|FAIL APPLY\|FAIL RESET\|FAIL UNKNOWN\|FAIL GLOBAL' ch11.log; then
  echo "FAIL: 검증 오류 로그 발견" >&2
  exit 1
fi
