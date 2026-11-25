#!/usr/bin/env bash
# 제23장: 원본 NPU/DSP RTL을 읽기 전용으로 컴파일하고 결과를 .build에 저장.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL="${RTL_DIR:-$ROOT/reference_rtl}"
if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
  echo "NOT_RUN: iverilog 또는 vvp 없음" >&2
  exit 2
fi
for name in npu_engine4.v npu_dsp_mac_lane.v dsp_multiplier.v; do
  if [[ ! -f "$RTL/$name" ]]; then
    echo "NOT_RUN: RTL 파일 없음: $RTL/$name" >&2
    exit 2
  fi
done
mkdir -p "$ROOT/.build/ch23"
cd "$ROOT/.build/ch23"
iverilog -g2012 -s tb_npu_integrated -o sim \
  "$RTL/npu_engine4.v" "$RTL/npu_dsp_mac_lane.v" \
  "$RTL/dsp_multiplier.v" "$ROOT/tb/ch23/tb_npu_integrated.sv"
vvp sim | tee simulation.log
grep -q '^PASS CH23 cases=8 rejected=4$' simulation.log
