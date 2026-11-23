# 제22장 검증 기록 v02

독립 저장소 루트 `Yuul-Jung/system_verilog_uvm_tb`.

- 대상: `ch22_multi_agent_vip_v02.html`, `tb/ch22/tb_axi_multiagent_irq.sv`, `scripts/run_ch22.sh`.
- DUT 원본: `reference_rtl/axi4lite_slave_adapter.v` (Blob `eadaf8d3580023bed0c9b06f3e9b2a99de0cf266`), `reference_rtl/custom_register_bank.v` (Blob `49e5d0219574d1bcb9086dc99f259c191e35d82e`). 원본 수정 없음.
- 정적 검사 PASS: AXI 및 레지스터 뱅크 포트 전체 연결, 두 Agent, 버스 독립 Monitor, Reset/IRQ Monitor, 두 Analysis Imp, Virtual Sequence, W1C 상태, 네 쓰기·열한 읽기·IRQ 두 건·리셋 두 건의 계획·집계 코드.
- 교정 사항: 가상 Interface Config DB 경로를 `uvm_test_top.*`에서 `uvm_test_top*`로 수정하여 상위 Test와 하위 Agent 모두에 적용. HTML 구조도에서 Agent 간 잘못된 직결 화살표 수정.
- HTML 정적 검사 PASS: 제6부 CH22, 11개 절, 중복 id 없음, RTL 원본·UVM 전체 코드·실행 스크립트 포함, 기존 CSS/JS 유지, v02 목차 연결.
- RTL_SIM: **NOT_RUN**. Verilator+UVM으로 실제 컴파일·시뮬레이션한 로그 없음.
- BROWSER_VISUAL: **NOT_RUN**. 실제 브라우저 렌더링 미검증.
- PAGES_HTTP: **NOT_RUN**. GitHub Pages 실제 접속 미검증.
- 예정 출력 `PASS CH22 AXI_W=4 AXI_R=11 IRQ=2 RESET=2`는 실제 로그가 아니다.

Ubuntu에서 `bash scripts/run_ch22.sh` 실행 후 `.build/ch22/build.log`, `.build/ch22/simulation.log` 및 VCD를 확인해야 한다.
