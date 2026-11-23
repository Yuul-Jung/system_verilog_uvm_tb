#!/usr/bin/env bash
# 제12장: xrun 기능 커버리지 지원 환경에서 실행.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RTL="${1:-}"
if [[ -z "$RTL" || ! -f "$RTL" ]]; then
  echo "NOT_RUN: pwm_core.v 파일 경로를 첫 인자로 지정하세요" >&2
  exit 2
fi
if ! command -v xrun >/dev/null 2>&1; then
  echo "NOT_RUN: xrun 기능 커버리지 시뮬레이터 없음" >&2
  exit 2
fi
RTL="$(realpath "$RTL")"
mkdir -p "$ROOT/out/ch12"
cd "$ROOT/out/ch12"
xrun -64bit -sv -coverage functional -covoverwrite -access +r \
  "$RTL" "$ROOT/tb/ch12/tb_pwm_coverage.sv" -R -l ch12.log
