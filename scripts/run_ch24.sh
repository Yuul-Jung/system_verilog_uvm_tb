#!/usr/bin/env bash
# Ubuntu: bash scripts/run_ch24.sh
# Python 실행기가 컴파일·3시드·음성 시험·보고서를 처리한다.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 "$ROOT/scripts/run_ch24.py" "$@"
