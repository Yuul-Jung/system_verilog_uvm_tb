# 제22장 v03 검증 기록

## 원본 및 대응
- 제15·21장과 동일한 reference_rtl/axi4lite_slave_adapter.v eadaf8d3580023bed0c9b06f3e9b2a99de0cf266, custom_register_bank.v 49e5d0219574d1bcb9086dc99f259c191e35d82e 유지.
- amd_soc_p2 03.2장 IRQ, 04.2장 AXI 및 10.3장 레지스터 사양과 CONCEPT_ONLY. 현행 설계 파일 동일성 미확인. 교육용 VIP-style 구성으로 상용 AMD AXI VIP가 아니다.

## 적대적 검토 및 수정
- 이전 모델은 AXI B 수락 시 IRQ clear를 반영하고 이벤트만 별도로 관찰하므로 bank commit과 이벤트가 같은 클록일 때 실제 set 우선 정책을 보존하지 못한다. 실제 bank 공개 입력을 상승 에지에서, IRQ 상태를 +1ns에서 수집하도록 변경. 매 클록 독립 수식 (old & ~clear) | set 및 case inequality 비교.
- 실제 commit offset/data/strb를 큐에 저장하고 B 완료 거래와 비교한다. IRQ 기대값은 DUT 출력에서 얻지 않는다. 다만 commit 시점은 실제 bank 입력 관찰을 사용하며 모든 commit 타이밍 오류의 독립 예측기는 아니다.
- IRQ 읽기는 AR 수락 시각의 pre-edge 기대 상태를 조회. 현재 시나리오에서 AR/R 사이 별도 이벤트 경합은 직접 자극하지 않는다. CONTROL/DATA_IN은 순차 B 모델 유지.
- fork/join으로 W1C=3과 EV_BOTH_ON_CLEAR를 동시 실행. 이벤트 Driver가 실제 bank wr_en/offset/data/strb에 정렬하여 같은 commit 에지에서 두 set 비트와 두 clear 비트가 겹친다. 충돌 횟수=1 및 IRQ=11 확인. WSTRB=0000에서 W1C 무효 추가. IRQ가 비어 있지 않은 상태에서 재리셋.
- AXI Monitor의 X/Z·중복 수락 검사 및 B/R 유지 비교를 수락 에지까지 강화. 두 Agent의 시퀀스 반환, 19개 거래, 실제 6개 commit, IRQ 이벤트 비트 4개, 리셋 구간 2개, 충돌 1개, zero strobe 1개, 미결 거래 없음 확인. check/report phase 및 UVM 오류 누계 검사.
- CORRUPT_IRQ 부정 시험은 충돌 시 관찰 객체의 bit0을 반전한다. IRQ_MISMATCH status=10 expected=11 collisions=1 전용 진단을 기대한다. 실제 DUT 변이는 아니다.
- TB f4ced8faff3b8814ade94dbd3b33b071829fd1f5, script 1fd266eed8a23a0fed0fe89ee4c4cfd007bbd646. XSIM 내장 UVM -L uvm, 정상/부정 개별 실행. 설치 환경 실제 호환성 미검증.

## 독립 계산과 정적/모의 검증
- 독립 정수 상태 모델에서 6개 쓰기, 13개 읽기, IRQ 이벤트 비트 4개, 리셋 2구간, 충돌 1회, zero strobe 1회 확인. IRQ 경로 00→01→11→10→00→11→11→00. 최종 CONTROL/DATA_IN/IRQ 모두 0. TB의 호출 수와 일치. 실제 HDL 실행 아님.
- 원격과 동일 Blob의 로컬 스크립트 bash -n 성공. 모의 도구 9/9: 정상, 부정 exit1, 전용 진단 누락, 진단 값 오기, 부정 PASS, 부정 timeout, 정상 PASS 누락, 정상 UVM_ERROR=1, 정상 exit1. 실제 시뮬레이션이 아닌 판정 시험.
- 동일 Blob SVG 051bc26e7b064db4ebd17bf1e5efac46b5e0f940 Chromium 렌더 및 스크린샷 확인. 텍스트 20개, 서로 겹침 0, viewBox 초과 0. 분석 경로가 DUT 경로와 교차하지 않도록 수정.
- HTML d95300032b33190b6c5bcb56945be167e04a9fcf: 전체 두 RTL/TB/스크립트 원문 일치, 인라인 SVG 일치, 8절, 24장 탐색/INDEX, 중복 ID 없음, 교시 및 대표 민감 패턴 제거 확인.

## 판정
- 스냅샷 보존·독립 계산·Bash 문법·모의 판정·SVG 단독 렌더·원격 정적 검사 완료.
- 실제 RTL_SIM/UVM 정상/부정 및 실제 변이 NOT_RUN: xvlog/xelab/xsim/iverilog/verilator 부재. UVM 스케줄러에서 실제 동시 거래 실행은 미확인.
- 미결 AXI 거래 중 리셋, AR/R 사이 이벤트 경합 직접 자극, 임의 AXI 병렬 거래 및 완전한 규격 검증 범위 밖.
- 전체 HTML/모바일/Pages 실접속 및 편집기 JSON 왕복 NOT_RUN. 호환 JSON 미제작.
