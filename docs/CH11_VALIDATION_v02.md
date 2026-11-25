# 제11장 v02 검증 기록

## 원본 매칭
- amd_soc_p2 04.2장 02·06절, p2_04_2_rtl_v02.html (f42a821b9a35572d0940c24d6781bafb8287f21e).
- 현행 legacy/part02_1/ch04/rtl/pwm_core.v 및 reference_rtl/pwm_core.v Blob e813f3fb107bd327054d11e0b397817b8e7bd813 동일. 원본 RTL 변경 없음. 공개 13포트만 연결, AXI 및 보드 제외.

## 적대적 검토 및 수정
- 다섯 기존 assert property를 유지. 단일 클록 선행 조건의 |->와 |=>, Preponed/NBA 구별 및 disable iff의 비샘플 리셋 예외 설명 보강.
- 기존 테스트에서는 선행 조건이 발생하지 않아도 위반이 없는 공허한 통과를 구별하지 못했다. 상승 에지의 정상 입력/공개 상태로 각 선행 조건을 집계하는 *_hits와 최종 checks=4, apply_hits=4, 다른 조건 발생 여부를 검사한다. 이 집계는 SVA 엔진 실행이나 정식 assertion coverage를 입증하지 않는다.
- 정상 동작 중 출력 X/Z 검사 및 리셋 직전 HIGH 선행 조건 추가. 리셋 차단은 461ns 검사이며 동기 상태 초기화는 원본의 465ns 동작 계약이다.
- 조건부 VCD, 외부 경로를 작업 폴더 이동 전에 realpath로 해결, xrun 전용 스크립트를 독립 저장소의 XSIM 우선 실행으로 변경. 실제 설치 환경의 도구 명령 및 실행 결과는 미검증. Icarus 전체 SVA 지원을 가정하지 않음.
- AMD UG900 2024.1/2026.1 공식 Test Bench Feature 표에서 concurrent assertion, implication, assert statement, disable iff 지원 명시 확인. https://docs.amd.com/r/en-US/ug900-vivado-logic-simulation/Test-Bench-Feature
- TB afa35df396962ee283981fa264999ca801e4230a, 스크립트 edca9244172c5f797ebb68fd3924d74a5f7ffa96. 전체 RTL/TB/스크립트를 HTML에 수록. 수업 시간 배분 제거.

## 독립 시간 계산 (RTL 실측 아님)
| 듀티 | 요청 ns | 수락 ns | 적용 ns | pending 확인 샘플 ns | 절차 확인 ns |
|---:|---:|---:|---:|---:|---:|
| 0 | 40 | 45 | 105 | 55 | 170 |
| 8 | 180 | 185 | 265 | 195 | 310 |
| 4 | 320 | 325 | 345 | 335 | 450 |
| 2 | 490 | 495 | 555 | 505 | 620 |

- 고정 8클록 상태와 에지 직전 샘플을 따로 계산. 185ns 새 요청은 해당 경계에 즉시 적용되지 않고 265ns에 적용. 455ns 갱신 뒤 counter=3, duty=4로 HIGH, 460ns 리셋 인가, 461ns LOW 기대. 465ns 내부 리셋, 480ns 해제.
- 정상 예상 선행 조건 횟수: reset 5, disabled 16, apply 4, zero 16, full 8. 절차적 적용 검사 4회. 이 값은 실제 시뮬레이션의 통과 횟수가 아님.
- 가상 반례: pending 유지 실패, 100% 출력 LOW, 리셋 전 LOW, 자극 누락, X/Z. 예상 검출 경로만 논리 확인. 실제 변이 및 assertion 활성화 확인 시험 미실행.
- SVG 단독 Chromium 렌더 및 스크린샷 확인: 텍스트 14개, 겹침 0, viewBox 초과 0. 원격 SVG d9b1a15ad5b8e4e470acfb3ead4360ced05593bf가 로컬 렌더 원본과 일치하고 HTML 인라인도 동일. 시간 도식은 편집기 JSON 미제작.
- 원격 HTML addfeb4438593d708d59b000335ae07dfa8d0894: 전체 RTL/TB/스크립트 문자 일치, 8절, 24장 탐색 데이터 및 INDEX 링크, 중복 ID 없음, 예상/실측 구분 및 배포 독립성 정적 확인.

## 판정
- 원본 대조·독립 시간 계산·SVG 단독 렌더·원격 정적 검사: PASS (해당 범위).
- 실제 RTL_SIM(XSIM), 어설션 실행 및 오류 주입 시험: NOT_RUN — 로컬에 xvlog/xelab/xsim/xrun 없음.
- 전체 HTML·모바일·Pages 실접속 및 편집기 JSON 왕복: NOT_RUN.
