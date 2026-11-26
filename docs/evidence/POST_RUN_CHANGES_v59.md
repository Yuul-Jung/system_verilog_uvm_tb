# v59 증거 실행 후 변경 기록

[v59 증거](v59/README.md)의 로그는 실행 당시의 소스 바이트와 짝을 이룹니다. 2026-11-26 독립 적대적 검증에서 찾은 결함을 고치면서 아래 소스가 실행 이후 바뀌었습니다. v59 증거 파일은 그대로 보존하고, 바뀐 파일의 실행 당시·현재 SHA256과 재실행 범위는 [기계 판독 기록](POST_RUN_CHANGES_v59.json)에 남깁니다. `python3 scripts/collect_evidence.py --verify`는 이 기록과 정확히 일치하는 변경만 허용하고, 영향받는 장을 함께 출력합니다.

| 변경 파일 | 결함 | 재실행 | 결과 |
|---|---|---|---|
| `tb/ch23/tb_npu_integrated.sv` | 길이 65 거부가 미적재 검사에 가려짐, 뉴런 0·2·3 편향과 연산 중 쓰기 미시험 | Icarus Verilog 12.0 | PASS. [로그](post_run_v59/ch23_simulation.log) |
| `tb/ch14/tb_uart_fifo_flow.sv` | 프레이밍 오류 경로 미시험 | Icarus Verilog 12.0 | PASS. [로그](post_run_v59/ch14_simulation.log) |
| `tb/ch11/tb_pwm_sva.sv` | `ap_disabled_low`의 선행 조건이 duty=0 구간에서만 발생해 enable 차단 누락을 구별하지 못함 | Verilator 5.054 (XSIM 대체) | 정상 PASS, 부정 `DETECTED_SVA_PENDING t=55`. [정상](post_run_v59/ch11_verilator.log) · [부정](post_run_v59/ch11_verilator_negative.log). **XSIM NOT_RUN** |
| `scripts/run_chapter.sh` | Vivado가 없으면 Icarus 장도 종료 코드 1 | Icarus Verilog 12.0, Vivado 없는 환경 | 01·04·14·23장 종료 코드 0. [실행 기록](post_run_v59/ch01_runner.txt) |
| `scripts/collect_evidence.py` 외 시험 2개 | Verilator `%Error` 미검출, 계정명 단어 전역 치환 | 시험 실행 | `test_review_fixes.py`, `test_evidence_completeness.py`를 root·일반 계정에서 통과 |
| HTML·`course.json`·`assets/site.js` | 제11·14·23장 새 버전 링크 | `validate_course.py` | PASS |

함께 바뀐 `scripts/bootstrap_local_tools.sh`는 v59 증거의 대상 파일이 아닙니다. 수정 후 빈 폴더에서 Verilator 5.054와 Z3 설치까지 다시 실행해 확인했습니다.

검증 장비에 Vivado가 없어 XSIM 8개 장(11·12·17~22)은 이번에 XSIM으로 다시 실행하지 않았습니다. 이 가운데 TB가 바뀐 것은 제11장뿐입니다. 나머지 7개 장의 TB·RTL은 v59 증거와 같습니다.
