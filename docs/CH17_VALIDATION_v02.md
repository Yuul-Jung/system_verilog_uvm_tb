# 제17장 v02 검증 기록

## 원본 매칭
- amd_soc_p2 04.2장 RTL·AXI 풀이 02절 Shadow/Active 및 06절 독립 PWM Core 전체, p2_04_2_rtl_v02.html f42a821b9a35572d0940c24d6781bafb8287f21e.
- legacy/part02_1/ch04/rtl/pwm_core.v와 reference_rtl/pwm_core.v Blob e813f3fb107bd327054d11e0b397817b8e7bd813 동일. 원본 변경 없음.

## 적대적 검토 및 보강
- 기존 HIGH/LOW 2시점 비교는 중간 오동작을 놓칠 수 있다. 사용되지 않던 expect_ports를 현재 표본 검사로 변경하여 8개 연속 하강 에지의 6개 공개 출력(활성 설정 4개, pending, pwm_out)을 비교한다. 리셋 출력/극성 확인 및 요청 직후 기존 비활성 상태 확인 추가.
- test의 objection 종료 조건을 일부 카운트가 아닌 env.done으로 변경. env가 모든 검사 및 기록을 마친 뒤 done=1. check_phase에서 8회 및 done 확인. report_phase의 UVM_ERROR/FATAL 누계 및 스크립트의 최종 요약 확인.
- config_db 경로를 uvm_test_top.env로 한정하고 NO_VIF로 설정 생략. build_phase의 NOVIF fatal 전용 진단 및 PASS 부재 요구. connect_phase는 프레임워크 단계일 뿐 별도 구현 없음. env가 자극 및 검사를 직접 담당하는 최소 구성 유지.
- 기존 범용 Verilator 5.x 전제 대신 AMD UG900의 XSIM 내장 UVM 라이브러리 경로 적용. xvlog/xelab -L uvm, xsim -testplusarg NO_VIF. 공식 자료: https://docs.amd.com/r/2023.2-English/ug900-vivado-logic-simulation/Universal-Verification-Methodology-Support 및 https://docs.amd.com/r/en-US/ug900-vivado-logic-simulation/Universal-Verification-Methodology-UVM-Support
- 설치 버전별 UVM 기능/매크로/로그 형식 실검증 필요. TB d33f194f1576e592a8d27879a73daf84767ae558, script 5c96d704a65c8ae0004b92ca08e028f69dca3d61.

## 독립 계산과 검증 결과
- 10ns 클록, 5/15/25ns reset 상승 에지, 30ns reset 해제, 40ns 요청·45ns 수락, 50ns pending 확인, 105ns 적용, 110~180ns 하강 에지에서 11110000 예상. 정확히 8개 표본. 적용 시점 자체를 강제하는 별도 assertion은 없음. pending 해제 기준으로 관찰하므로 일관되게 이동한 적용 시점 오류 등은 놓칠 수 있다.
- 스크립트와 동일 Blob 로컬 사본의 bash -n 종료 0. 모의 도구 로그 및 종료 상태 시험 8/8 기대 일치: 정상, 부정 종료 코드 1, 부정 진단 누락, 부정 PASS, 부정 타임아웃, 정상 PASS 누락, UVM_ERROR 1, 정상 비정상 종료. 실제 UVM 실행이 아닌 판정 로직 시험이다.
- SVG Chromium 단독 렌더링에서 하단 두 텍스트의 경계 상자 겹침 1건 수정. 재렌더·스크린샷 확인: 21개 텍스트, 겹침 0, viewBox 초과 0. 원격 SVG 30dbb5c76ea6f2b83c68908abd582956192bd032와 로컬 렌더 원본 및 HTML 인라인 일치.
- 원격 HTML ac67d5e56e3aec351ff05b29778ac9413134206b: 전체 RTL/TB/스크립트 일치, 8절, 24장 탐색 및 INDEX, 중복 ID 없음, 시간 배분 및 대표 민감 패턴 검사 통과.

## 판정
- 원본 대조·독립 시간 계산·Bash 문법/모의 판정·SVG 단독 렌더·원격 정적 검사 PASS(해당 범위).
- 실제 RTL_SIM/XSIM UVM 정상·부정 실행 NOT_RUN(로컬 xvlog/xelab/xsim/iverilog/verilator 부재). 실제 UVM 엔진의 phase/objection, 로그 형식 및 NOVIF 검출은 미검증.
- 전체 HTML·모바일·Pages 접속·편집기 JSON 왕복 NOT_RUN.
