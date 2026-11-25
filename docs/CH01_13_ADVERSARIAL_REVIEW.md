# 제01~13장 적대적 종합 검증 — 2026-11-25

## 범위 및 기준
- 검토 시작 HEAD: e8bccd92e55ca4d86cffe2bc28d45eec74ed8b67. 대상 과정 system_verilog_uvm_tb의 최신 01~13장, 원본 RTL 2개, TB 13개, 실행 스크립트 13개, package/interface/reference model, INDEX 및 course.json, site.js, 원본 설계 매칭표.
- 원본 설계 저장소 읽기 전용. amd_soc_npu UART Echo는 첫 주석 차이만 확인, amd_soc_p2 PWM은 검증 스냅샷과 Blob SHA 일치. 원본 불변: UART 28160c34522e47fbd961466651598da063bc74ae, PWM e813f3fb107bd327054d11e0b397817b8e7bd813.
- 설계 참조, 코드, 신호, 샘플 시점, 실패 경로, 학습 순서, 목차와 보안을 검토. 실제 시뮬레이션과 정적 검토를 구분한다.

## 확인된 결함 및 조치
| 장 | 반례 / 결함 | 조치 | 판정 |
|---|---|---|---|
| 04 | 한 듀티 시험을 생략하면 errors=0, checks=9로 PASS 가능 | checks=11 확인, 스크립트 정확한 완료 행 검사 | 수정 및 정적 재검증 |
| 05 | 한 입력/자료형 시험 누락 시 failures=0으로 PASS 가능 | checks=6 확인, 스크립트 정확한 완료 행 검사 | 수정 및 정적 재검증 |
| 06 | IDLE 또는 STALL을 생략해도 기대 큐가 비고 failures=0 가능 | checks=11 확인, 스크립트 정확한 완료 행 검사 | 수정 및 정적 재검증 |
| 07 | 사례 일부 누락 시 checked가 4 미만이어도 PASS 출력 | checked=4 확인, 스크립트 정확한 완료 행 검사 | 수정 및 정적 재검증 |
| 10 | 리셋 직후 출력 LOW와 다음 에지 초기화만 확인하면 비동기 레지스터 리셋 변이도 통과 가능 | 489ns에서 기존 활성 상태 보존 검사 추가, 496ns 초기화 검사 유지 | 수정 및 논리 재검증 |
| 11 | SVA 비활성화 시 선행 조건 집계와 절차 검사만으로 PASS 가능 | 기존 ap_apply_pending 결론에 부정 시험 관찰 조건 추가, +INJECT_SVA_PENDING에서 55ns 전용 진단 및 정상 PASS 부재 요구 | 수정 및 정적/모의 스크립트 재검증 |
| 01~12 | 이전 발행본 탐색 데이터 잔존, 리다이렉트 경유 | 01~13장 최신 24개 탐색 주소 동기화, INDEX/course.json 갱신, 6개 이전 발행 경로 호환 유지 | 재조회 PASS |

추가로 수정 중 문자열 치환의 Bash 인용 오류가 04~07장 실행 스크립트에 발생하여 즉시 수정했다. 최종 실제 원격 Blob과 일치하는 로컬 사본 5개(04/05/06/07/11장)의 bash -n 모두 종료 코드 0. 04~07장은 정확한 완료 행, 잘못된 횟수, 완료 행 누락, 비정상 종료 네 가지씩 16건, 11장은 정상/부정 결과 판정 7건(기대 진단과 종료 코드 0/1, 어설션 무시, 다른 실패, PASS 동시 출력, 정상 로그 누락/오류)을 모의 실행했다. 총 23개 모의 판정이 기대와 일치했다. 이 시험은 가짜 시뮬레이터의 로그·종료 상태로 실행 스크립트를 시험한 것이며 RTL 실행은 아니다.

## 장별 판단
| 장 | 판정 및 범위 |
|---|---|
| 01 | 관찰 전용으로 유지. 6포트 조합 전달, 수락 에지나 UART 직렬 통신 검증 아님. |
| 02 | 동기 상태와 조합 출력 차단의 시간 구분 적정. 관찰 전용. |
| 03 | task/function 반복과 타임아웃 적정. 기대값 자동 판정 전 단계. |
| 04 | HIGH 개수 비교의 순서 결함은 명시된 교육 범위이며 12장에서 보완. 비교 완료 횟수 추가. |
| 05 | 4상태 보존 및 2상태 변환 검토. 완료 횟수 추가. |
| 06 | 패키지·배열·큐 순서 검토. 실제 FIFO와 구분. 완료 횟수 추가. |
| 07 | clocking block 관찰/구동 경계 검토. 실제 도구 실행은 미확인. 완료 횟수 추가. |
| 08 | 클래스·제약·업캐스팅 검토. 모든 난수 조합/동적 디스패치 검증 아님. |
| 09 | DUT와 모델의 공통 오류 가능성은 남아 있음. 독립 계산표는 실제 검증기와 별개. 고정 시나리오 범위에 적정. |
| 10 | 오류 주입은 DUT 외부 경로로 분리. 상승 에지 이전 상태 보존 검사 추가. |
| 11 | SVA 엔진 부정 시험 추가. 한 속성의 활성화 검증이며 나머지 속성 각각의 실패 시험은 미실행. |
| 12 | 12개 교차 bin의 대표값, 96개 표본. 36개 합법 값 조합 전수와 다름. 실제 coverage DB 미생성. |
| 13 | 독립 모니터·수락 순서·대기 유지·X/Z 전파 검토. 실제 UART PHY/FIFO 및 연속 무유휴 거래 전체는 다음 장 검증 범위. |

## 최종 원격 재조회
- course.json v45, INDEX와 24개 장 데이터 일치(정적). 현재 13개 HTML 모두 8절, 전체 RTL/TB/필수 의존 파일 원문 일치, 중복 ID 없음, 명시된 시간 배분·절대 홈 경로·대표 토큰 패턴·원본 외부 저장소 링크 검사 통과. 이는 완전한 보안 스캔이나 브라우저 렌더링을 의미하지 않는다.
- 변경된 6개 장의 본문 코드와 스크립트 재대조(04~07장 본문은 직접 실행 명령 제공; 10~11장 전체 스크립트 일치). 도식 자체의 구조 변경 없음. 기존 장별 단독 렌더 기록은 역사적 근거로 유지.
- 현재 페이지 Blob:
  - ch01_testbench_basics_v04.html: f6de880ce86898edbf1d1ef17bd10ae94b84d40e
  - ch02_clock_reset_events_v03.html: 168e7e2c239af53c27e4247dbaf7bb951a56c51c
  - ch03_reusable_stimulus_v03.html: 6bfbd1fd41b863d791c9c5e6973687358740c0cf
  - ch04_pass_fail_automation_v04.html: 6f1cd80064b0357240edfb2e2206fcde77b0490f
  - ch05_verification_types_v04.html: 6ead83b059d2e6739f00ad0df6407e6a5163a1aa
  - ch06_arrays_queues_packages_v04.html: e87df713e4d3d3179cfccef16384e6033e153e4c
  - ch07_interface_modport_clocking_v03.html: 46348ad2a4753c655b4876da7bd7975171cce7fe
  - ch08_objects_constraints_v02.html: 2ee1117b813c75da102fa7650692c1e5a8f31c32
  - ch09_reference_model_scoreboard_v03.html: 655f51707fb1d772a6789a2860e9a733e1c3066f
  - ch10_corner_reset_timeout_v04.html: 906bd2a25e093270bdeb194ff81518594868bd7e
  - ch11_temporal_assertions_v03.html: a7aa52ff14dd0bacc7c23c9783dfacc2e55d417c
  - ch12_functional_coverage_v02.html: bc9c8d91fca2da2168ece2998882d5df76f7b2a4
  - ch13_uart_stream_verification_v02.html: 6c559adf7f533bf9ddf915f8c9e254c466796384

## 실제 실행의 한계
- RTL_SIM, 실제 오류 주입, SVA 엔진 실행, coverage 측정 및 xcrg 보고서: NOT_RUN. 로컬 xvlog/xelab/xsim/iverilog/vvp/verilator 없음.
- Chromium은 설치되어 있으나 원격 HTML의 전체 렌더링/모바일/클릭·복사 확인은 NOT_RUN. 컨테이너 DNS 해석 실패 및 웹 조회에서도 Pages 접근 불가. 사이트 자체 장애라고 단정하지 않는다.
- AMD UG900 2024.1의 xsim -testplusarg, -onerror, -ignore_assertions 및 2026.1/2026.2의 xelab -ignore_assertions와 sampled value functions 지원표를 대조했다. 실제 설치 버전 실행은 별도 필요. https://docs.amd.com/r/2024.1-English/ug900-vivado-logic-simulation/xsim-Executable-Options
- 기존 장별 검증 문서는 당시 발행본의 기록이며 이 보고서가 최신 보완 근거다.

## 최종 판정
01~13장 개정·정적 종합 검증 및 확인된 결함 수정 완료. 실제 HDL 실행 검증 미완료. 다음 제작 대상은 제14장 FIFO 및 흐름 제어. 실행 검증을 실시할 때 04~07장 완료 카운트, 10장 비동기 리셋 변이, 11장 정상/부정 어설션, 12장 실제 커버리지 DB를 우선 재검증한다.
