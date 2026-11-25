# 제15장 v02 검증 기록

## 설계 매칭 및 범위
- amd_soc_p2 04.2장 03~04절 AXI·WSTRB (p2_04_2_rtl_v02.html f42a821b9a35572d0940c24d6781bafb8287f21e), 10.3장 사양서 2~3절 (p2_10_3_ip_library_v02.html e5a4845e978d9432ddf079135080fd46d4cb8602), 03.2장 IRQ/AXI (p2_03_2_rtl_v02.html 72b36f774b69aa192c462a08a862f7d4842dc982) 직접 조회.
- 동일 모듈/파일 확인되지 않아 CONCEPT_ONLY 유지. PWM/IRQ IP의 실제 오류 정책을 범용 스냅샷의 OKAY 정책과 혼동하지 않음. 최신 설계 원본의 정확한 경로 및 기능 동일성 NOT_VERIFIED.
- 기존 reference_rtl/axi4lite_slave_adapter.v eadaf8d3580023bed0c9b06f3e9b2a99de0cf266, custom_register_bank.v 49e5d0219574d1bcb9086dc99f259c191e35d82e 불변. 두 파일의 전체 코드와 TB/실행 스크립트를 독립 배포.

## 결함 및 변경
- 실제 AW/W 수락을 별도 집계하고 commit 이전에 두 입력이 각각 수락되었는지 검사. 저장된 주소 하위 8비트·데이터·스트로브를 wr_en 샘플에서 대조. 수락 이후 live 입력을 변경해 저장 누락 반례를 노출.
- B/R 대기 중 BRESP/RRESP 유지 검사, AR 수락 후 다른 주소 제시로 RDATA 캡처 확인.
- 기존 AW-first/W-first 외 동시 AW/W, WSTRB 0000, VERSION RO 쓰기, 미매핑 0xFC 쓰기/읽기, 0x110 별칭, DATA_OUT 읽기 추가.
- 비어 있는 응답 상태 리셋 대신 B/R 응답 모두 대기 중이라는 선행 조건을 검사하고 reset으로 취소. 상태 초기화 및 이후 읽기 검증.
- 조건부 VCD, RTL_DIR 절대화, 정확한 완료 행 검사. XSIM 우선 절차.
- TB 2422b612e7bb210cc50f607b02f2a8c44b4cba6e, script 512b754d7beee67515c77814e171081840985fcf.

## 독립 레지스터 모델 계산 (실행 로그 아님)
| 자극 | 기대 |
|---|---|
| DATA_IN 전체 쓰기 11223344 | 11223344 |
| AABBCCDD, WSTRB=0101 | 11BB33DD |
| CONTROL 5 | enable=1, mode=2 |
| FFFFFFFF, WSTRB=0000 | DATA_IN 11BB33DD 유지 |
| VERSION 쓰기 | 00010000 유지 |
| 미매핑 FC 쓰기/읽기 | 읽기 0, OKAY |
| 110 읽기 | 11BB33DD (하위 8비트 별칭) |
| DATA_OUT | 12345678 |
| CONTROL 7 commit, B/R 대기, reset | 두 응답 취소, CONTROL/DATA_IN 0 |

- 독립 모델에서 7개 쓰기, 13개 읽기 주소, 2개 응답 취소, 완료 B 6 + R 12 = 18 확인. 실제 AXI 시간 시뮬레이션이나 SV 스케줄러 실행 아님. 초안 계산에서 RESET을 읽기로 분류한 오류를 수정 후 재계산.
- 원격 HTML bf9c5055a642a57dae469be910d126724c0e4239, SVG 1bf3940cbe825fd126beefc7aa094ac3a5f50b90. 전체 두 RTL/TB/스크립트 원문 일치, 8절, 24장 탐색/INDEX, 중복 ID 및 민감 패턴 정적 검사 통과. 7개 AW/W 호출, 6개 B 완료 호출, 12개 read_expect 호출 및 1개 별도 AR 취소 경로 확인.
- SVG 정적 구조 검토. 브라우저 렌더링, 편집기 JSON 왕복, 실제 Pages 접속 NOT_RUN.
- 실제 RTL_SIM(XSIM/Icarus), 변이 시험 및 Bash 실실행: NOT_RUN. 로컬 xvlog/xelab/xsim/iverilog/vvp/verilator 명령 부재.
- COMMAND 펄스, IRQ W1C/event 우선, 모든 경합, 보호 및 전체 AXI 규격은 미검증. 현행 PWM/IRQ IP의 실제 검증은 별도 필요.
- 판정: 스냅샷 보존·독립 레지스터 계산·원격 정적 검사 완료. 설계 동일성 미확인 및 실제 RTL 실행 미검증.
