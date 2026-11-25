# 제21장 v02 검증 기록

## 원본 및 설계 대응
- amd_soc_p2 04.2장 03~04절 (p2_04_2_rtl_v02.html f42a821b9a35572d0940c24d6781bafb8287f21e), 10.3장 사양서 2~3절 (e5a4845e978d9432ddf079135080fd46d4cb8602), 03.2장 03절 (72b36f774b69aa192c462a08a862f7d4842dc982) 확인. CONCEPT_ONLY 유지. 현행 PWM/IRQ IP의 동일 파일 경로 및 기능 동일성 미확인.
- 제15장과 같은 기존 스냅샷: axi4lite_slave_adapter.v eadaf8d3580023bed0c9b06f3e9b2a99de0cf266, custom_register_bank.v 49e5d0219574d1bcb9086dc99f259c191e35d82e. 원본 불변. 교육용 단일 미결 정책과 OKAY 정책을 현행 IP의 오류 정책과 구분한다.

## 발견 및 수정
- 기존 Top의 uvm_test_top.*는 Test 자체를 명시하지 않는다. Test·Driver·Monitor 경로를 정확히 설정.
- CONTROL의 실제 유효 비트는 3개. value 1비트와 mode 2비트 RW, 예약 29비트 RO 모델로 변경. FFFFFFFF 쓰기 뒤 기대 Mirror/읽기값 00000007 확인.
- Driver의 완료 요청 객체를 Predictor에 연결하던 구조 대신 독립 Monitor가 실제 AW/W/B, AR/R 핸드셰이크에서 새 거래를 재구성한다. X/Z 입력 및 응답 검사, B/R 수락 시 안정성 확인. Predictor는 해당 상승 에지에서 동작하고 Driver 완료는 다음 하강 에지. 실제 UVM 엔진 타이밍 미검증.
- auto_predict=0. 첫 쓰기 직후 읽기 이전 Mirror 비교로 read prediction이 누락된 write prediction을 가리는 반례를 방지. NO_PREDICT 부정 시험에서 첫 DATA_IN 쓰기 직후 PREDICT_WRITE 전용 진단 기대.
- 전체 레지스터 접근만 수행, supports_byte_enable=0, WSTRB=1111 관찰. 부분 WSTRB 및 필드별 접근은 별도 시험. 모델 reset과 실제 DUT reset 구분.
- 읽기 7/쓰기 3의 실제 수락 수와 주소/데이터, 완료 상태 및 미결 거래 없음 확인. check_phase/report_phase 및 오류 누계 판정. 기존 요약행의 UVM_ERROR/FATAL 0도 오류로 오인하는 grep 제거. XSIM 내장 UVM 경로 사용.
- TB 3f3b89b11d854a93b17b6b1ac64b1a2d84b89f40, script 3b655f27712f7008e431caddefab92c54815fdf1.
- 공식 참고: https://docs.amd.com/r/2023.2-English/ug900-vivado-logic-simulation/Universal-Verification-Methodology-Support ; https://github.com/accellera/uvm/blob/master/distrib/src/reg/uvm_reg_predictor.svh

## 독립 기대값 계산과 정적 검증
- 순차 10거래: R00=0, R10=0, W10=11223344, R10=11223344, W00=FFFFFFFF→7, R00=7, W00=5, R00=5, R18=00010000, R1C=524D4150. 독립 정수 모델 계산과 TB 호출 개수 일치. 최종 CONTROL=5, DATA_IN=11223344.
- 실제 스크립트 동일 Blob 로컬 사본 bash -n 종료 0. 실제 실행 및 모의 로그 판정은 NOT_RUN.
- SVG f000c1bb3edb45eb1e63eff494b8a64962cd4cda 동일 Blob 로컬 Chromium 단독 렌더 및 스크린샷 확인: 19개 텍스트, 겹침 0, viewBox 초과 0.
- HTML 955068459788f1f7fa9805bf34ba7ae762d4e4fe: 전체 두 RTL/TB/스크립트 원문 일치, 인라인 SVG, 8절, 24장 탐색 및 INDEX, 중복 ID 없음, 대표 민감 패턴 검사 통과.

## 판정 및 남은 범위
- 원본 스냅샷 보존·독립 레지스터 계산·Bash 문법·SVG 단독 렌더·원격 정적 검사 완료.
- 실제 UVM/RAL/XSIM 실행, 부정 실행, 변이 검증 NOT_RUN. 로컬 xvlog/xelab/xsim/iverilog/verilator 없음. 설치 버전별 RAL 및 로그 형식의 실제 검증 필요.
- RO 상수 읽기만 수행. RO 쓰기, 부분 WSTRB, STATUS/COMMAND/IRQ_STATUS/DATA_OUT RAL 모델, W1C/W1P, 다중 미결 및 모든 AXI 규격 검증은 범위 밖.
- 전체 HTML/모바일/Pages 접속 및 편집기 JSON 왕복 NOT_RUN. 호환 JSON 미제작.
