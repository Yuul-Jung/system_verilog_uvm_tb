#!/usr/bin/env bash
# 제20장 UVM Factory/Config/Objection 검증. DUT 원본 수정 금지.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DUT_PATH="${DUT_PATH:-$ROOT/reference_rtl/pwm_core.v}"
TB_PATH="$ROOT/tb/ch20/tb_pwm_factory_config_objection.sv"
OUT="$ROOT/.build/ch20"

if [[ ! -f "$DUT_PATH" || ! -f "$TB_PATH" ]]; then
  echo "NOT_RUN: PWM DUT 또는 제20장 테스트벤치 파일이 없습니다." >&2
  exit 2
fi
if ! command -v verilator >/dev/null 2>&1; then
  echo "NOT_RUN: Verilator가 설치되지 않았습니다." >&2
  exit 2
fi
if [[ -z "${UVM_HOME:-}" || ! -f "$UVM_HOME/src/uvm_pkg.sv" ]]; then
  echo "NOT_RUN: UVM_HOME/src/uvm_pkg.sv를 찾지 못했습니다." >&2
  exit 2
fi

mkdir -p "$OUT"
verilator --version | tee "$OUT/verilator_version.txt"

# --binary 실행 파일, --timing 지연/이벤트, --assert 검증,
# --trace VCD 파형 지원, -Wno-fatal 경고만으로 빌드 중단하지 않음.
verilator --binary --timing --assert --trace -Wno-fatal \
  --top-module tb_pwm_factory_config_objection \
  --Mdir "$OUT/obj_dir" +incdir+"$UVM_HOME/src" \
  "$UVM_HOME/src/uvm_pkg.sv" "$DUT_PATH" "$TB_PATH" \
  2>&1 | tee "$OUT/build.log"

(cd "$OUT" && ./obj_dir/Vtb_pwm_factory_config_objection \
  +UVM_TESTNAME=pwm20_test | tee simulation.log)

# 성공 종료에 더해 Trace Driver의 실행과 Scoreboard 완료를 확인한다.
if ! grep -q 'PASS CH20 factory=traced config=3 applied=3' "$OUT/simulation.log"; then
  echo "FAIL: Factory·Config·Scoreboard 판정이 완료되지 않았습니다." >&2
  exit 1
fi
if ! grep -q 'FACTORY_TRACE.*DRIVE duty=2' "$OUT/simulation.log"; then
  echo "FAIL: Traced Driver의 실제 작동 증거가 없습니다." >&2
  exit 1
fi
if grep -Eq 'UVM_(FATAL|ERROR) @[[:space:]]*[0-9]+|UVM_(FATAL|ERROR)[[:space:]]*:[[:space:]]*[1-9]' "$OUT/simulation.log"; then
  echo "FAIL: UVM 오류 메시지가 기록되었습니다." >&2
  exit 1
fi
echo "PASS CH20 SUITE: factory override + config DB + 3 applied transactions"
echo "빌드 로그: $OUT/build.log"
echo "실행 로그: $OUT/simulation.log"
