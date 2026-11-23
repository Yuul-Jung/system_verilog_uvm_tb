#!/usr/bin/env bash
# 제10장: 원본 RTL을 읽기 전용으로 사용하여 컴파일/시뮬레이션한다.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DUT_PATH="${DUT_PATH:-$ROOT/reference_rtl/pwm_core.v}"
if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
  echo "NOT_RUN: iverilog 또는 vvp 미설치" >&2
  exit 2
fi
test -f "$DUT_PATH" || { echo "FAIL: DUT 파일 없음" >&2; exit 1; }
mkdir -p "$ROOT/.build/ch10"
iverilog -g2012 -s tb_pwm_corner_reset_timeout -o "$ROOT/.build/ch10/sim.out" \
  "$DUT_PATH" "$ROOT/tb/ch10/tb_pwm_corner_reset_timeout.sv"
vvp "$ROOT/.build/ch10/sim.out"
