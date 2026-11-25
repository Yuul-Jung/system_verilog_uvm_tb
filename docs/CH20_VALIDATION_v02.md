# 제20장 v02 검증 기록

## 원본 및 범위
- amd_soc_p2 04.2장 RTL·AXI 풀이 02절 Shadow/Active 및 06절 독립 PWM Core, p2_04_2_rtl_v02.html f42a821b9a35572d0940c24d6781bafb8287f21e.
- legacy/part02_1/ch04/rtl/pwm_core.v와 reference_rtl/pwm_core.v Blob e813f3fb107bd327054d11e0b397817b8e7bd813 동일. 원본 불변.
- 고정 주기 8, 기본 극성, 초기 리셋 및 순차 요청. 전체 AXI/보드, 임의 주기, 겹치는 요청 및 동작 중 리셋은 범위 밖.

## 적대적 검토와 개선
- 기존 제20장이 제19장의 개선된 매 클록 독립 기대 모델을 유지하지 않고 pending 하강 이벤트에 의존하던 문제를 수정. 매 에지 입력/출력 관찰 및 cycles % 8 기반 독립 기대 상태를 유지한다.
- Factory 교체를 생략한 NO_OVERRIDE에서 실제 타입 $cast 실패와 FACTORY 진단 확인 경로 구성. 기본 Driver create와 가상 drive_one/super 호출 유지.
- Config 전달을 env.ag.drv와 env.sb 경로로 한정. Test의 settings와 두 컴포넌트 cfg 참조 동일성 확인. seq.cfg는 직접 전달이며 Config DB를 통해 얻는 것이 아님. ALT_PLAN으로 1,8,3을 설정하고 동일 검증 환경에서 시험. 고정 배열 길이 3 및 duty 범위 검사.
- 설정 객체는 공유 참조이며 DUT 출력에서 생성되지 않는다. 실행 중 수정하지 않는 계약이며 임의 구성 오염 전체를 독립 검증하지 않는다. 외부 스크립트는 두 계획별 완료 문자열과 trace 3개를 확인.
- seq.start 반환 후 임의 2클록 대신 마지막 전체 주기 표본까지 objection 유지. EARLY_DROP에서 세 번째 적용 직후 종료하도록 하여 check_phase 누락 검출 경로 구성. 실제 phase drain 및 스케줄러는 미실행.
- 정상 2종, 부정 3종을 XSIM에서 각각 실행하도록 변경. UVM 오류 누계와 정확한 진단 및 부정 PASS/timeout 부재 확인.
- TB b0c758b1d0943d70858fc6f95b8bda53702ecfe2, 실행 스크립트 29b0874a20ce90a87ed033adc9d4f8d20b7ce424.

## 독립 시간 계산 (HDL 실행 아님)
| 시나리오 | 첫 주기 106~176ns | 두 번째 186~256ns | 세 번째 266~336ns |
|---|---|---|---|
| 기본 2,6,0 | 11000000 | 11111100 | 00000000 |
| ALT_PLAN 1,8,3 | 10000000 | 11111111 | 11100000 |
- 3회 reset 관찰, 비활성 7개, 활성 24개, 총 34개. 적용 관찰 106/186/266ns, 정상 종료 예상 340ns. EARLY_DROP는 세 번째 적용 관찰 266ns 직후 270ns에 시퀀스 완료, 17개 활성 표본에서 종료 예상(추가 drain 지연 없다는 가정). 실제 UVM 스케줄러 검증 필요.
- 원격 스크립트와 동일 Blob 로컬 사본 bash -n 성공. 모의 도구 13/13 판정 일치: 정상, 부정 종료1, 잘못된 ALT_PLAN, trace 누락/초과, PASS 누락, UVM_ERROR, 정상 비정상 종료, FACTORY/NO_CFG 진단 누락, 조기 종료 표본 수 오기, 부정 PASS/timeout. 모의 로그/종료 판정 시험이며 HDL 실행이 아니다.
- SVG 9d87f5f5181dde990299af9ddf9176adbe0937d8와 동일 Blob 로컬 사본 Chromium 단독 렌더 및 스크린샷 확인. 텍스트 23개, 서로 겹침 0, viewBox 초과 0.
- HTML 30ea6eed343d181ec8cc50fef900f759a95ece78: 원본/TB/스크립트 전체 일치, 인라인 SVG, 8절, 최신 24장 탐색 및 INDEX, 중복 ID 없음, 대표 민감 패턴과 시간 배분 검사 통과.

## 판정
- 원본 일치, 독립 계산, Bash 문법·모의 판정, SVG 단독 렌더, 원격 정적 검사 완료.
- 실제 RTL_SIM/UVM 정상·부정 실행과 RTL 변이 검증 NOT_RUN. 로컬 xvlog/xelab/xsim/iverilog/verilator 없음. 전체 HTML·모바일·Pages 접속·편집기 JSON 왕복 NOT_RUN. 호환 JSON 미제작.
