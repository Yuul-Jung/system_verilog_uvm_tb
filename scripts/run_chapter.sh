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
source scripts/setup_env.sh
case "$-" in
  *x*) exec bash -x "$runner" ;;
esac
exec bash "$runner"
