# 제23장 v02 검증 기록

- 원본 RTL 유지: reference_rtl/npu_engine4.v 066218754ddfcc7807eff7333b308c207ab28175, reference_rtl/npu_dsp_mac_lane.v a9dae4662d2aaa82cb6ba629597650217d30e0d9, reference_rtl/dsp_multiplier.v 3dfb157f0e34dfb548fff7b3a6e5911ba664d504.
- v01의 지연 오류: 시작 수락 에지 이후 READ/ISSUE 각 L회, DRAIN1/2 각 1회이므로 2L+2. E0 기준 L=1/2/64는 4/6/130클록. 실제 RTL 상태 전이 정적 대조.
- TB에 64비트 독립 정수 참조 모델, load_bias ready, busy 계약, 실제 동점, 64주소 및 signed 극값, 잘못된 길이 0/65·미적재·리셋 이후 거부를 추가. 8 정상 및 4 거부 예정.
- 독립 BigInt 계산: 64×(-32768)×(-32768)+(2^39-1)=618475290623; 64×(-32768)×32767-2^39=-618473193472. 41비트 signed 범위 내.
- HTML의 전체 원본 RTL 3개, TB, 스크립트의 escaped 코드 본문 일치 정적 검사. 24장 탐색과 INDEX/manifest v02 동기화.
- 실제 HDL 컴파일/실행 NOT_RUN (iverilog/verilator 부재). 브라우저 렌더 및 Pages 접속 NOT_RUN. UVM class 기반 통합 TB가 아닌 SystemVerilog 독립 참조 모델 실습. Busy 중 쓰기·start 충돌 및 실제 합성·보드 검증은 범위 밖.
