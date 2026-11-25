# 제16장 v02 검증 기록

## 원본 및 대응
- amd_soc_npu 제1장 UART 계산기 04절 서브젝트 1-2 MAC 누산, 06절 서브젝트 1-4 MAC 파이프라인, p01_uart_calc_v01.html f1089413362a271717b6a4b6a2e95deb569334f2.
- ch01/rtl/mac_core.v와 reference_rtl/mac_core.v Blob d3f911b882f65e8f6096d76d31a2b710c18ae38d 일치.
- ch03/rtl/mac_pipeline_core.v와 reference_rtl/mac_pipeline_core.v Blob f690b2db2a16626a43e0bb9f3c859d616e57116d 일치.
- 두 원본 RTL 불변. 실제 NPU 통합, DSP 합성/타이밍/전력 검증은 범위 밖.

## 적대적 검토 및 보강
- 기존 양의 누산 오버플로 표기 구간은 16129-16256+16384+16129=32386으로 32767 이하이다. 실제 양방향 범위 초과 사례 추가.
- 기존 DATA_WIDTH=8, ACC_WIDTH=16은 부호 확장 복제 수 0. ACC_WIDTH=24의 기본·파이프라인 DUT를 추가해 부호 비트 복제의 기능을 검증하도록 변경.
- 기대값을 32비트 정수로 계산 후 비교할 때만 하위 16/24비트 사용. Python은 임의 정밀도 정수와 입력 이력을 사용한다.
- clear 직전 보류 곱 1 및 reset 직전 보류 곱 81의 폐기를 구별. 버블은 이전 곱 배출 가능. 최초 리셋은 3개 상승 에지로 코드 주석 수정.
- 기존 최소 valid 횟수 조건을 21클록, 기본 12회, 파이프라인 10회 및 양방향 범위 초과 확인·최종 누산값 확인으로 변경.
- 조건부 VCD, RTL_DIR 절대화, 정확한 완료 행 검사, XSIM 우선 명령.
- TB ac229caf024416a2e2ee481cc0695f891edcfb28, 실행 스크립트 9dcc1727c5cc92f90500e8be91d8c63029f0a3b9, Python 0bb0fdf34b1458a705e23cf2ed81d19a73b00f03.

## 실제 독립 Python 계산 및 정적 교차검증
- 원격 파일과 Git Blob SHA가 동일한 Python 사본을 python3로 실제 실행(종료 0). MODEL CH16 cycles=21 basic_valid=12 pipe_valid=10 출력. TB apply 18회 및 최초 리셋 3회에서 독립 JS 계산도 동일.
| cycle | basic16 | pipe16 | basic24 | pipe24 | valid B/P |
|---:|---:|---:|---:|---:|---|
| 8 | 32386 | 16257 | 32386 | 16257 | 1/0 |
| 9 | -17021 | 32386 | 48515 | 32386 | 1/1 |
| 10 | -17020 | -17021 | 48516 | 48515 | 1/1 |
| 11 | 0 | 0 | 0 | 0 | 0/0 |
| 15 | 30 | -51 | 30 | -51 | 1/0 |
| 16 | 0 | 0 | 0 | 0 | 0/0 |
| 19 | 16768 | -32512 | -48768 | -32512 | 1/1 |
| 20 | 16768 | 16768 | -48768 | -48768 | 0/1 |
| 21 | 16768 | 16768 | -48768 | -48768 | 0/0 |
- 논리 반례: 포화 연산 변이는 9번째 기본 경로에서 불일치, zero extension은 음수 곱의 24비트 경로에서 불일치, 파이프 지연 누락 및 보류 곱 미폐기는 valid/누산 비교에서 불일치. 실제 변이 실행 아님.
- Bash 스크립트 동일 Blob 로컬 사본 bash -n 종료 0. 실행 스크립트의 실제 시뮬레이터 실행은 미실행.
- SVG 동일 Blob 8237bb267007ae97b9049bdcef7add14b80da3f3의 Chromium 단독 렌더 및 스크린샷 확인, 19개 text 겹침 0, viewBox 초과 0.
- HTML 7a0fe877dff4a67a342a66c9d950c6b0d991be22 전체 원본 RTL/TB/Python/실행 스크립트 일치(최종 TB 주석 수정 후 다시 확인), 8절, 24장 탐색, INDEX, 중복 ID 없음 및 공개 민감 패턴 검사.

## 판정
- 원본 동일성, 독립 Python 실행/JS 계산, Bash 문법 검사, SVG 단독 렌더, 원격 정적 검사 PASS(각 범위).
- RTL_SIM(XSIM/Icarus), 실제 변이, 전체 HTML·모바일·Pages 접속, 편집기 JSON 왕복 NOT_RUN. 로컬 RTL 시뮬레이터 명령 부재.
