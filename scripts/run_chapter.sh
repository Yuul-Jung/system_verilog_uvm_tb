#!/usr/bin/env bash
# VS Code와 증거 수집기가 동일한 실행 경로를 사용한다.
set -eo pipefail
if [[ $# -ne 1 || ! "$1" =~ ^(0[1-9]|1[0-9]|2[0-4])$ ]]; then
  echo 'ERROR: chapter must be 01..24' >&2
  exit 2
fi
COURSE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
chapter="$1"
case "$chapter" in
  11|12) runner="tb/ch$chapter/run_ch$chapter.sh" ;;
  *) runner="scripts/run_ch$chapter.sh" ;;
esac
cd "$COURSE_ROOT"
# (변경) 환경 점검은 경고만 한다. Vivado가 없어도 Icarus·Verilator 장은
# 실행할 수 있고, 각 장 실행기가 필요한 도구를 다시 확인한다.
if ! source scripts/setup_env.sh; then
  echo "WARN: 일부 도구가 없습니다. 이 장에 필요한 도구는 장별 실행기가 확인합니다." >&2
fi
case "$-" in
  *x*) exec bash -x "$runner" ;;
esac
exec bash "$runner"
