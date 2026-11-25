# 제07장 v02 검증 기록

## 원본 매칭
- amd_soc_npu 제1장 UART 계산기 03절 서브젝트 1-1 UART 에코, p01_uart_calc_v01.html (f1089413362a271717b6a4b6a2e95deb569334f2).
- 검증 스냅샷 28160c34522e47fbd961466651598da063bc74ae, 현행 common/rtl/uart_echo_controller.v 76269e771295fadcd0ddf160bee4556fdfa62e56. 직접 조회 결과 주석 행을 제외한 본문 일치. 형식 등가 검증 아님. 원본 RTL 불변.
- 인터페이스 uart_stream_if.sv 58df482471f59c09368f8e26748704f05cacfd39 변경 없음. 기존 TB의 6포트 연결 및 clocking 시나리오 유지.

## 수정 및 기술 확인
- 전체 RTL, interface, TB를 독립 폴더에 저장해 실행하도록 구성. 설계 학습안내서의 정확한 장절, 계층도, 포트 방향, 관찰과 구동을 분리한 타이밍 SVG 추가. 시간 배분 제거.
- TB는 조건부 VCD 기록만 추가. TB 8e4f8474cfedceb2523e03249ade2ff75589e50d, 실행 스크립트 cfd159a43caec9067d5ab8052b1501356125e536. Verilator -DVCD 및 --trace 사용, 지연 없는 원본의 TIMESCALEMOD 경고만 제외. 실제 컴파일은 미수행.
- AMD UG900 2024.1 및 2026.1/2026.2 문법 지원표에서 clocking blocks and modports(25.5.5) 지원 표기 확인. 구버전 지원은 다를 수 있다. XSIM 우선 절차로 반영. 참고: https://docs.amd.com/r/2024.1-English/ug900-vivado-logic-simulation/Running-SystemVerilog-in-Standalone-or-prj-Mode
- Verilator의 주된 2상태 모델 특성 및 버전별 clocking 지원 한계 명시. X/Z 검증을 대체하지 못한다. 참고: https://verilator.org/guide/latest/languages.html
- tb_clk은 관찰용이며 DUT에 연결되지 않음. adapter는 연결 전용. agent는 일반 SV 모듈이며 UVM Agent가 아님. 문자 Z(5A)와 고임피던스 Z 구별.

## 독립 이벤트 계산 (실측 아님)
| ns | 에지 직전 관찰 | 이후 구동 |
|---:|---|---|
| 5 | 검사 없음 | 41/1/1 |
| 15 | A_ACCEPT 41/1/1 | 5A/1/0 |
| 25 | Z_STALL 5A/1/0 | ready=1, data/valid 유지 |
| 35 | Z_ACCEPT 5A/1/1 | valid=0 |
| 45 | IDLE 5A/0/1 | 종료 |

- 직전 입력을 조합 출력에 매핑하고 다음 입력을 별도로 계산하는 모델로 4개 기대 사례 일치. 실제 SV 이벤트 스케줄러 동작은 미검증. 첫 5ns 검사 반례 및 stall 중 입력 변경 반례를 본문에 설명.
- SVG 단독 Chromium 렌더: 최초 텍스트 겹침 6쌍, 중간 수정 1쌍, 최종 26개 텍스트 겹침 0·viewBox 초과 0. 스크린샷 확인. 원격 SVG 10243d97d86b24d8638bbcad65fe9b1143ff87de와 로컬 렌더 원본 일치. 타이밍 도식이므로 편집기 flow JSON 미제작.
- 원격 HTML 5c9ce211afecc03af8e8ef0ea194db52b9b16930: RTL/interface/TB 원문 일치, 8절, 24장 탐색, INDEX 링크, 중복 ID 없음, 예상 결과·배포 독립성 정적 검사 완료.

## 판정
- 원본 대조, 독립 이벤트 계산, SVG 단독 렌더링 및 원격 정적 검사: PASS (각 범위에 한함).
- RTL_SIM(XSIM/Verilator): NOT_RUN — 실행 명령 부재.
- 전체 HTML·모바일·Pages 실제 접속: NOT_RUN.
