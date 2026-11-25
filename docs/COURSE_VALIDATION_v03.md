# 6부 24장 실제 실행·적대적 검증 v03

검증일: 2026-11-26 KST. 대상은 [독립 검토 v58](INDEPENDENT_REVIEW_v58.md)의 V58-01~08이다. 기준 커밋은 `10d0ec0`, 중앙 규칙은 `rule_md` @ `028248a19afc66e9aafdab393fbe0de10a3930ca`이다. 원본 `reference_rtl/`과 `tb/`는 이번 작업에서 변경하지 않았다.

## 1. 여덟 항목의 수정과 검증

| 항목 | 수정 | 실제 검증 | 판정 |
|---|---|---|---|
| V58-01 | VS Code는 Bash와 공통 `run_chapter.sh` 호출. 01~24 입력 제한, 11·12장 실경로 분기 | 24개 경로·7개 잘못된 입력 반례 및 24장 실제 실행 | PASS |
| V58-02 | 파일별 실제 링크, 절 존재·ID·번호 제목, SVG 자체의 이름 검사 | 기존 검사기 전체 실행에서 세 반례의 거짓 통과 재현 → 새 검사기는 모두 exit=1. 정상 입력은 exit=0 | PASS |
| V58-03 | 과거 로그와 이번 순차 실행의 명령·종료 코드·핵심/전체 로그·소스/로그 SHA256 공개 | 공개 로그 해시 재계산, 12개 부정 시험 별도 종료 코드 측정, 로그 변조 반례 거절 | PASS |
| V58-04 | 나머지 17장 포함 24장 전체에 실측 발췌·상태·증거 링크 추가 | 주 TB 24개 및 파일명 코드 박스 76개 본문 일치, 관찰 3장/자동 PASS 21장 구분 | PASS |
| V58-05 | 구버전 66개는 최신 HTML로 이동, Git 이력 보존 | Chrome에서 66개 실제 이동과 #s01 보존 확인 | PASS |
| V58-06 | 모바일 표 스크롤·긴 파일명/절 제목/헤더 줄바꿈, CH15 줄 간격, CH24 합류 연결선 수정 | Chrome 24장×6폭=144화면, SVG 29개 전수 육안·소스 대조, 모바일 24장 육안 확인 | PASS |
| V58-07 | source_manifest 현행 표·도구·CH21 Monitor·CH22 19거래 반영, 과거 기록 별도 파일 분리 | 소스 SHA256 및 24개 실행 경로·판정과 대조 | PASS |
| V58-08 | CH08 정확한 `CH08 PASS: 4 cases checked` 행 필수 검사 | 실제 Verilator 실행, 완료 행 누락/횟수 변형/접두어/실행기 실패 반례 | PASS |

재현 가능한 반례·회귀 시험은 [18개 테스트 실행 로그](evidence/v59/regression_tests.txt)에 있다. 반례용 대역 시험과 실제 RTL 시뮬레이션을 구분해 기록했다.

## 2. 실제 실행과 공개 증거

- 제01~24장을 순차 재실행했고 장별 실행기 종료 코드는 모두 0이다. 도구는 Icarus 12.0, Verilator 5.054 + Z3 4.8.12, Vivado XSIM/xcrg 2024.2, Python 3.12.3이다.
- 제01~03장: `EXECUTED_OBSERVATION`. 자동 PASS 마커가 없는 원래 TB의 성격을 유지한다. 제04~24장: 자동 판정 PASS.
- 부정 시험 12건: 모두 전용 오류 검출. Icarus 오류 주입은 exit=1, 이번 XSIM SVA/UVM 부정 시험은 exit=0과 전용 Fatal을 반환했다. 종료 코드만으로 검출을 판정하지 않았다.
- CH12: 실제 cases=12, coverage=100.00%, xcrg 보고서와 정적 리소스 보존. CH24: 실제 세 시드 1/7/42와 음성 시험 report.json 보존.
- [장별 공개 로그·명령·코드](evidence/v59/README.md) · [기계 판독 증거 manifest](evidence/v59/manifest.json). 원본 로그의 raw_sha256과 개인정보 제거 후 public_sha256을 각각 기록한다.
- 과거 로그에 종료 코드가 없던 항목은 `NOT_RECORDED`다. 재실행으로 얻은 종료 코드와 섞어 추정하지 않았다.
- 초기 증거 수집에서는 export한 shell 추적 옵션이 Vivado에 nounset를 전달해 중단됐다. 추적을 장별 Bash에만 적용하도록 수집 경로를 고친 뒤 24장을 다시 실행했다. 이 중간 실패 로그는 로컬 `.build/evidence_v59_failed_trace/`에 보존하고 최종 PASS 실행과 구분했다.
- 대용량 `.build/`, `.tools/`는 커밋하지 않는다. 공개용 텍스트 로그, 선택 VCD 4개, XCRG 보고서, 측정 JSON, 압축 검토 이미지만 보존했다.
- 공백 검사에서는 실제 도구 출력의 후행 공백과 CH13의 원본 TB를 그대로 복사한 코드 행을 보존한다. 이 두 범위를 제외한 수정 코드·문서의 diff 공백 검사는 통과했다. 이를 위해 원본 TB나 증거 바이트를 서식 정리하지 않았다.

```bash
python3 scripts/test_review_fixes.py
python3 scripts/validate_course.py
python3 scripts/collect_evidence.py --verify
python3 scripts/check_timing_evidence.py
cd docs/evidence/v59
sha256sum -c SHA256SUMS
```

## 3. 24장 도식·시간 계약 전수 대조

각 행의 도식을 원본 RTL/TB의 명칭·포트·방향·조건과 역추적했다. 실측은 실행 로그 또는 선택 VCD로 확인했다. 타이밍 그림은 계속 예상/개념 도식으로 표기하며 실측 파형 이미지라고 바꾸지 않았다.

| 장 | 도식 수 | 소스·연결·시간 계약 대조 |
|---:|---:|---|
| 01 | 3 | 조합 6포트, 데이터/valid 정방향·ready 역방향. VCD 0/10/20/30ns 값과 대조. 콘솔은 다음 자극 이전 관찰임을 구분 |
| 02 | 2 | Shadow→Active, boundary 피드백, reset 게이팅. 35ns pending, 95ns duty=3, 190ns 출력 차단·195ns 레지스터 초기화 대조 |
| 03 | 1 | request_pwm→wait→observe_one_period, 0/2/4/6/8 듀티 및 8표본 반복 |
| 04 | 1 | DUT 출력과 독립 duty_ticks 비교 후 checks/errors 집계, 실제 checks=11 |
| 05 | 1 | uart_sample_t 10비트: data[9:2], valid[1], ready[0] 및 0x41 필드 배치 |
| 06 | 1 | packed[3-i]→unpacked[i]→push_back, 큐 front/back 순서·최종 queue=0 |
| 07 | 1 | input #1step/output #0, 5ns 구동과 15/25/35/45ns 순차 검사. 실제 VCD의 agent.checked 및 ready/valid 대조 |
| 08 | 1 | 상속→apply_and_check, 입력3/출력3, #1 안정화·네 사례 비교. DUT 클록 없음 |
| 09 | 1 | 같은 입력을 DUT와 독립 모델로 분기하고 공개 6출력을 posedge+#1에 비교, 72사이클 |
| 10 | 1 | cfg_apply 누락과 measured_pwm 관찰 반전의 서로 다른 경로, 정상48회/부정2건 |
| 11 | 1 | cfg_apply → 다음 에지 pending: 45ns 요청·55ns 다음 샘플. 실제 SVA 부정 Fatal t=55 |
| 12 | 1 | 3×2×2 교차 셀의 HIGH 개수. 실제 12개 CHECK 행을 도식 셀의 기대식과 대조 |
| 13 | 1 | UART Echo 바이트 조합 전달, ready 역방향, tb_clk는 DUT 외부 기준 |
| 14 | 1 | RX→RX FIFO 및 TX FIFO→TX, 반대 방향 ready, 각 FIFO16과 PHY 저장소 구분 |
| 15 | 1 | AW/W 독립 수락·B/R 역방향, wr/rd 레지스터 경로, 글자 줄 간격 보완 |
| 16 | 1 | 공통 입력→직접 누산 및 product_q 파이프라인, k와 k+1 유효 시점·clear/reset 폐기 |
| 17 | 1 | test/env→vif→bus→pwm_core, 공개 출력과 done 역방향, 10ns 공통 clk |
| 18 | 1 | Sequence→Sequencer→Driver→DUT, item_done 역방향, 3거래·24표본 |
| 19 | 1 | Agent 내부 sqr/drv/mon, bus 독립 관찰→ap→Scoreboard.write, cycles%8 |
| 20 | 1 | 생성 타입 교체·설정 참조 공유·objection 종료를 세 경로로 구분, 31+3=34관찰/활성24 |
| 21 | 1 | RAL→adapter→driver→DUT→독립 monitor→predictor→mirror, set_auto_predict(0) |
| 22 | 1 | virtual sequencer의 bus/IRQ 분기, 실제 bank commit과 두 monitor→Scoreboard 경로 |
| 23 | 2 | xmem/w/bias→4 lane→score/argmax, E0~E6·mul_valid 구간. VCD의 8개 완료 지연 6/4/130클록 대조 |
| 24 | 2 | 실행기→컴파일/시뮬레이션→보고서, SHA/도구/종료 분기. 교차하던 보고서 연결선을 명시적 공통 합류선으로 수정 |

- [47개 시간·값 대조 결과](evidence/v59/timing_checks.json)와 선택 공개 VCD 4개를 함께 제공한다.
- 현행 설계 안내서 5개와 RTL 10개 원격 SHA를 재조회했다. [설계 대응표](DESIGN_VERIFICATION_MAP.md)의 분류는 유지한다. CH23 현행 외부 엔진의 2클록 추가 계약은 기존 스냅샷과 구분한다.
- [76개 코드 박스 일치 결과](evidence/v59/codebox_checks.json): RTL·TB·보조 코드·실행 스크립트·CI 코드의 이름 표시 블록을 엔티티 해제 후 실제 파일과 비교해 모두 일치했다.

## 4. 브라우저와 시각 검증

- Chrome 158 headless, 밝은 교육용 테마. 폭 1920/1366/1024/768/390/320px를 24장 모두 확인했다.
- [144개 측정](evidence/v59/visual/measurements.json): 페이지 넘침 0, 헤더 내부 잘림 0, SVG 텍스트 경계/쌍별 겹침 경고 0. PART1개·해당부 CHAPTER4개·절목차 일치.
- 실제 클립보드 내용 비교 24장, 모바일 Enter/Escape 열기/닫기 72회, 데스크톱 절 링크 24회, [구버전 실제 이동 66개](evidence/v59/visual/redirects.json) 완료.
- 자동 검사 이후 도식 29개 전부의 글자·화살표·관통·합류를 이미지로 읽었다. 모바일 24장도 320px 이미지로 확인했다. 육안 검사에서 CH19/20의 overflow:hidden 내부 제목 잘림을 추가 발견해 공통 헤더 줄바꿈과 측정 조건을 보완하고 144화면을 다시 검사했다.
- 검토 이미지: [도식 1부](evidence/v59/visual/diagrams-part1.webp), [2부](evidence/v59/visual/diagrams-part2.webp), [3부](evidence/v59/visual/diagrams-part3.webp), [4부](evidence/v59/visual/diagrams-part4.webp), [5부](evidence/v59/visual/diagrams-part5.webp), [6부](evidence/v59/visual/diagrams-part6.webp).
- 모바일 이미지: [1부](evidence/v59/visual/mobile-part1.webp), [2부](evidence/v59/visual/mobile-part2.webp), [3부](evidence/v59/visual/mobile-part3.webp), [4부](evidence/v59/visual/mobile-part4.webp), [5부](evidence/v59/visual/mobile-part5.webp), [6부](evidence/v59/visual/mobile-part6.webp).

## 5. 발행 버전

course.json v58→v59, 24장 모두 새 파일을 발행했다. 구버전 본문은 Git 이력에서 확인할 수 있다.

| 장 | 버전 | 자료 |
|---:|---|---|
| 01 | v04 → v05 | [최신 HTML](../ch01_testbench_basics_v05.html) |
| 02 | v03 → v04 | [최신 HTML](../ch02_clock_reset_events_v04.html) |
| 03 | v03 → v04 | [최신 HTML](../ch03_reusable_stimulus_v04.html) |
| 04 | v04 → v05 | [최신 HTML](../ch04_pass_fail_automation_v05.html) |
| 05 | v04 → v05 | [최신 HTML](../ch05_verification_types_v05.html) |
| 06 | v04 → v05 | [최신 HTML](../ch06_arrays_queues_packages_v05.html) |
| 07 | v03 → v04 | [최신 HTML](../ch07_interface_modport_clocking_v04.html) |
| 08 | v03 → v04 | [최신 HTML](../ch08_objects_constraints_v04.html) |
| 09 | v03 → v04 | [최신 HTML](../ch09_reference_model_scoreboard_v04.html) |
| 10 | v04 → v05 | [최신 HTML](../ch10_corner_reset_timeout_v05.html) |
| 11 | v03 → v04 | [최신 HTML](../ch11_temporal_assertions_v04.html) |
| 12 | v02 → v03 | [최신 HTML](../ch12_functional_coverage_v03.html) |
| 13 | v02 → v03 | [최신 HTML](../ch13_uart_stream_verification_v03.html) |
| 14 | v02 → v03 | [최신 HTML](../ch14_fifo_flow_control_v03.html) |
| 15 | v02 → v03 | [최신 HTML](../ch15_axi4lite_register_verification_v03.html) |
| 16 | v02 → v03 | [최신 HTML](../ch16_mac_npu_integer_verification_v03.html) |
| 17 | v03 → v04 | [최신 HTML](../ch17_minimal_uvm_environment_v04.html) |
| 18 | v03 → v04 | [최신 HTML](../ch18_sequence_driver_v04.html) |
| 19 | v04 → v05 | [최신 HTML](../ch19_monitor_agent_scoreboard_v05.html) |
| 20 | v03 → v04 | [최신 HTML](../ch20_factory_config_objection_v04.html) |
| 21 | v03 → v04 | [최신 HTML](../ch21_uvm_register_abstraction_v04.html) |
| 22 | v04 → v05 | [최신 HTML](../ch22_multi_agent_vip_v05.html) |
| 23 | v03 → v04 | [최신 HTML](../ch23_npu_integrated_scoreboard_v04.html) |
| 24 | v03 → v04 | [최신 HTML](../ch24_regression_ci_reporting_v04.html) |

## 6. 개인정보·한계·원격 확인

- 공개 묶음은 개인 홈/임시 경로·이메일·토큰·실제 로컬 계정/호스트 패턴을 검사해 제거했다. XCRG의 User 항목도 대체 표기다. 원본 raw 로그는 로컬에 남고 공개 파일의 해시는 누구나 검증할 수 있다.
- 실제 브라우저 검증은 설치된 Chrome으로 수행했다. 다른 브라우저·OS의 폰트 차이는 NOT_RUN이다. 지원 테마는 기존 밝은 테마이며 임의 테마를 추가하지 않았다.
- Vivado 합성·보드 실행, 현행 외부 NPU 엔진을 이용한 새 TB 실행은 NOT_RUN이다. 이번 대상은 원본 스냅샷의 시뮬레이션 검증이다.
- GitHub Actions CH24 원격 재실행은 NOT_RUN이다. 이 작업에서 해당 워크플로의 대상 RTL/TB/스크립트를 변경하지 않았다.
- 커밋·푸시 후 GitHub 원격 SHA·공개 파일과 기존 Pages의 발행본 일치를 확인한다.
