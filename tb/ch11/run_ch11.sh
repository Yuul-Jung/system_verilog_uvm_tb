#!/usr/bin/env bash
# 제11장: 원본 RTL은 외부 저장소에서 읽기 전용으로 준비한다.
set -euo pipefail
RTL="${1:-}"
if [[ -z "$RTL" || ! -f "$RTL" ]]; then
  echo "NOT_RUN: pwm_core.v 경로를 첫 인자로 지정하세요" >&2
  exit 2
fi
if ! command -v xrun >/dev/null 2>&1; then
  echo "NOT_RUN: SVA 지원 xrun 시뮬레이터가 없습니다" >&2
  exit 2
fi
mkdir -p out/ch11
cd out/ch11
xrun -64bit -sv -assert -access +r "$RTL" ../../tb/ch11/tb_pwm_sva.sv -R -l ch11.log
