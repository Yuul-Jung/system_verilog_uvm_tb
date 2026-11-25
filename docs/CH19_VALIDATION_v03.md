# 제19장 v03 검증 기록

## 원본 및 범위
- amd_soc_p2 04.2장 02절 Shadow/Active, 06절 독립 PWM Core 전체. 안내서 p2_04_2_rtl_v02.html f42a821b9a35572d0940c24d6781bafb8287f21e.
- legacy/part02_1/ch04/rtl/pwm_core.v와 reference_rtl/pwm_core.v Blob e813f3fb107bd327054d11e0b397817b8e7bd813 일치. 원본 불변.
- 8클록 고정 주기, 기본 극성, 초기 리셋, 순차 듀티 2/6/0. 임의 주기, 임의 리셋, 모든 중첩 요청 및 AXI/보드는 별도 범위.

## 적대적 검토와 조치
- 기존 pending 하강 이벤트만으로 관찰을 선택하면 pending의 결함에 의해 적용 관찰이 누락될 수 있고, 적용 직후 PWM 검사만으로는 중간 위상 오류를 놓친다.
- Monitor는 매 상승 에지 +1ns에 새로운 4상태 pwm19_sample 객체로 입력과 공개 출력 전송. Scoreboard는 관찰된 클록 수의 modulo 8로 위상을 계산하고 관찰한 요청과 독립 계획 배열을 대조한다. DUT 내부 counter 또는 pending 하강을 기대 시점의 기준으로 사용하지 않는다.
- 적용 경계에서 이전 요청을 먼저 반영한 뒤 새 요청을 처리. 매 표본에서 active_* 4개, pending 및 PWM 비교. APPLIED 로그는 예상 적용 사건이며 해당 표본의 실제 비교 및 최종 PASS가 필요하다.
- 기존 임의 2클록 대기 대신 마지막 활성 표본 완료까지 objection 유지, 다음 하강 에지 종료. check_phase에서 reset_samples=3, cycles=31, samples=24, driven/requests/applied=3 및 미결 요청 없음 확인. report_phase에서 오류 누계 확인.
- CORRUPT_SAMPLE은 126ns의 관찰 객체만 반전. DUT 변이는 아님. SB_PWM t=126 phase=2 expected=0 got=1 진단과 정상 PASS 부재를 확인하는 부정 실행 추가.
- XSIM 내장 UVM 우선, 제18장과 동일한 -L uvm 및 -testplusarg 방식. 설치 버전의 실제 UVM 호환성은 미확인.
- TB d12ad2064363538a666c4b58658fcdfed3deb603, 스크립트 2ef7f241fdd7b40f61abfa172f79d61c20d2f3eb.

## 독립 시간 계산 (실제 HDL 실행 아님)
| duty | 구동 ns | 수락 ns | 요청 관찰 ns | 적용 관찰 ns | 표본 ns | PWM |
|---:|---:|---:|---:|---:|---|---|
| 2 | 40 | 45 | 46 | 106 | 106~176 | 11000000 |
| 6 | 120 | 125 | 126 | 186 | 186~256 | 11111100 |
| 0 | 200 | 205 | 206 | 266 | 266~336 | 00000000 |
- 초기 리셋 관찰 6/16/26ns. 비활성 7개(36~96), 활성 24개(106~336), 총 34개 관찰. 340ns 종료 예상. 시간 없는 UVM 거래 전달을 가정한 독립 계산이다. 실제 UVM 스케줄러/RTL 동작을 입증하지 않는다.
- Bash: 원격과 동일 Blob 로컬 사본 bash -n 성공. 모의 로그·종료 상태 9/9 기대 판정 일치(정상, 부정 종료1, 진단 누락, 위상 오기, 부정 PASS, 부정 timeout, 정상 PASS 누락, 정상 UVM_ERROR, 정상 비정상 종료). 가짜 도구로 스크립트 판정만 검증했다.
- SVG: 최초 렌더에서 공개 신호 관찰 라벨과 경로가 겹치는 결함 1건 수정. 동일 Blob ed67569fb6a5a5c45d5d21214324b07a50fbb4aa Chromium 재렌더 및 스크린샷 확인. 텍스트 19개, 텍스트끼리 겹침 0, viewBox 초과 0. 라벨과 선의 관통 수정 확인.
- 최종 HTML 03dd6ba9316a66b6c4d2d1e3d249f7610e576fb7: 원본·TB·스크립트 전체 일치, 인라인 SVG 동일, 8절, 24장 탐색과 INDEX, 중복 ID 및 대표 민감 패턴 검사. 제20장 실제 제목과 연계 문구 대조.

## 판정
- 원본 매칭·독립 시간 계산·Bash 문법 및 모의 판정·SVG 단독 렌더·원격 정적 검사 완료.
- 실제 RTL_SIM/UVM 정상·부정 실행 및 실제 변이 검증 NOT_RUN: 로컬 xvlog/xelab/xsim/iverilog/verilator 없음.
- 전체 HTML/모바일/Pages 실접속 및 편집기 JSON 왕복 NOT_RUN. 호환 JSON 미제작.
