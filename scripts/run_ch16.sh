#!/usr/bin/env bash
# 제16장: 원본 RTL 사본 두 개를 변경하지 않고 컴파일한다.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RTL="${RTL_DIR:-$ROOT/reference_rtl}"
if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
  echo "NOT_RUN: iverilog/vvp 설치 필요" >&2
  exit 2
fi
for f in mac_core.v mac_pipeline_core.v; do
  if [[ ! -f "$RTL/$f" ]]; then
    echo "NOT_RUN: $RTL/$f 없음" >&2
    exit 2
  fi
done
mkdir -p "$ROOT/.build/ch16"
cd "$ROOT/.build/ch16"
iverilog -g2012 -s tb_mac_integer -o sim \
  "$RTL/mac_core.v" "$RTL/mac_pipeline_core.v" \
  "$ROOT/tb/ch16/tb_mac_integer.sv"
vvp sim | tee simulation.log
grep -q '^PASS CH16 ' simulation.log
