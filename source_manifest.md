# Source Manifest
- **과정:** `system_verilog_uvm_tb`
- **검증 DUT:** `Yuul-Jung/amd_soc_rtl/part03/common/rtl/uart_echo_controller.v`
- **검증 DUT Blob SHA:** `28160c34522e47fbd961466651598da063bc74ae`
- **원본 출처:** `amd_soc_rtl` 기본 브랜치(첫 작성 시 확인)
- **접근:** 복사·변경 없이 상대경로 또는 `DUT_PATH` 환경변수로 참조
- **교육용 새 파일:** `tb/ch01/tb_uart_echo_basics.sv`, `scripts/run_ch01.sh`
- **기준 규칙:** `Yuul-Jung/rule_md` @ `d1b8278d41fca8f5e3960736f3ac9d377e462fda`
- **시뮬레이션:** NOT_RUN (작성 환경에서 Icarus Verilog 실행 미실시)

## 제02장 · PWM 코어 재사용
- **검증 DUT:** `part02_1/ch04/rtl/pwm_core.v`
- **DUT 원본 Blob SHA:** `e813f3fb107bd327054d11e0b397817b8e7bd813`
- **원본 유지:** 원본 파일을 읽기 전용으로 참조한다. 기존 RTL·타이밍·포트를 변경하지 않는다.
- **신규 파일:** `tb/ch02/tb_pwm_clock_reset.sv`, `scripts/run_ch02.sh`, `ch02_clock_reset_events_v01.html`.
- **파라미터:** `RESET_PERIOD=8` (TB 인스턴스에서만 지정), 10ns 클록.
- **검증 시점:** 설정 Shadow 저장 t=35ns, Active 적용 t=95ns, 리셋 재인가 t=190ns와 내부 레지스터 초기화 t=195ns.
- **실행 상태:** NOT_RUN (제작 환경에서 Icarus를 실행하지 못해 실제 로그·VCD가 없음). 기대값은 별도 순차/조합 논리 대조.

## 제03장 · PWM 반복 자극 검증
- **검증 DUT:** `part02_1/ch04/rtl/pwm_core.v` (기존 제02장과 동일한 원본)
- **DUT 원본 Blob SHA:** `e813f3fb107bd327054d11e0b397817b8e7bd813`
- **작업 범위:** `system_verilog_uvm_tb/` 내부에서만 TB·HTML·실행 스크립트 작성. 원본은 읽기 전용.
- **신규 파일:** `tb/ch03/tb_pwm_reusable_stimulus.sv`, `scripts/run_ch03.sh`, `ch03_reusable_stimulus_v02.html`
- **TB 설정:** `RESET_PERIOD=8`, `cfg_period=8`, `cfg_duty` 0·2·4·6·8, 10ns 클록, `cfg_polarity=0`, `cfg_enable=1`.
- **학습 문법:** `task`, `function`, `repeat`, `for`, `wait`; 설정 요청·적용·관찰 흐름 분리.
- **검증 수준:** HTML·본문·TB 포트 정적 검증 완료. Icarus 컴파일/실행·VCD·실브라우저는 **NOT_RUN**.

## 제04장 · PASS/FAIL 자동 판정
- **검증 DUT:** `part02_1/ch04/rtl/pwm_core.v`.
- **원본 Blob SHA:** `e813f3fb107bd327054d11e0b397817b8e7bd813`.
- **신규 파일:** `tb/ch04/tb_pwm_pass_fail.sv`, `scripts/run_ch04.sh`, `ch04_pass_fail_automation_v02.html`.
- **조건:** `RESET_PERIOD=8`, `cfg_period=8`, 10ns 클록, 듀티 0·2·4·6·8.
- **검증 상태:** 정적 포트·링크·문서 검사 완료, RTL_SIM **NOT_RUN** (시뮬레이터 미설치).

## 제05장 · SystemVerilog 검증 자료형
- **원본 DUT:** `part03/common/rtl/uart_echo_controller.v`
- **원본 Blob SHA:** `28160c34522e47fbd961466651598da063bc74ae`
- **포트·시간 계약:** 조합 6포트, `rx_data_i→tx_data_o`, `rx_valid_i→tx_valid_o`, `tx_ready_i→rx_ready_o`. 클록·리셋 없음.
- **신규 파일:** `tb/ch05/tb_uart_types.sv`, `scripts/run_ch05.sh`, `ch05_verification_types_v02.html`
- **검증:** 정적 포트·링크·도식·문법 검토 완료. RTL_SIM **NOT_RUN** (시뮬레이터 미설치).

## 제06장 · 배열·큐·패키지
- **원본 DUT:** `part03/common/rtl/uart_echo_controller.v`
- **원본 Blob SHA:** `28160c34522e47fbd961466651598da063bc74ae`
- **포트 계약:** 6개 포트의 순수 조합 전달, 클록·리셋·FIFO 없음. TB 관찰용 `#1`은 DUT 지연 아님.
- **신규 파일:** `tb/ch06/uart_expect_pkg.sv`, `tb/ch06/tb_uart_arrays_queues.sv`, `scripts/run_ch06.sh`, `ch06_arrays_queues_packages_v02.html`.
- **검증 범위:** packed/unpacked 인덱스, 4개 데이터 queue, ready/valid 수락, 패키지 타입 재사용.
- **검증:** 정적 코드·문서·포트 검사. RTL_SIM **NOT_RUN** (현재 실행 환경에 Icarus/Verilator 없음).

## 제07장 · interface·modport·clocking block
- **검증 DUT:** `part03/common/rtl/uart_echo_controller.v` (기존 원본, 수정 없음)
- **원본 Blob SHA:** `28160c34522e47fbd961466651598da063bc74ae`
- **원본 계약:** rx_data_i→tx_data_o, rx_valid_i→tx_valid_o, tx_ready_i→rx_ready_o; 조합회로·클록 없음.
- **새 interface:** `tb/ch07/uart_stream_if.sv`; 6개 신호, `modport TB/DUT`, `clocking cb`.
- **새 TB:** `tb/ch07/tb_uart_interface.sv`; `uart_echo_bind`는 포트 연결 전용, `uart_stream_agent`는 구동·관찰.
- **실행 스크립트:** `scripts/run_ch07.sh` (Verilator 옵션 `--binary --timing --trace`).
- **배포 페이지:** `ch07_interface_modport_clocking_v01.html`.
- **입력 계약:** tb_clk 10ns는 TB 샘플링 기준이며 원본 DUT에는 미연결. input #1step / output #0.
- **시나리오:** A_ACCEPT → Z_STALL → Z_ACCEPT → IDLE (Ready/Valid 전송 대기 상태에서 데이터 유지).
- **판정:** 포트·HTML·링크·실습 계획 정적 점검 완료. RTL_SIM **NOT_RUN** (실행 도구 미설치).

## 2026-11-23 · 독립 저장소 이전
- 정본 저장 위치: `Yuul-Jung/system_verilog_uvm_tb/`의 루트.
- 원본 스냅샷: `reference_rtl/uart_echo_controller.v` (Blob `28160c34522e47fbd961466651598da063bc74ae`), `reference_rtl/pwm_core.v` (Blob `e813f3fb107bd327054d11e0b397817b8e7bd813`).
- 두 RTL 파일은 원본과 바이트 단위로 동일하게 보존하며 `scripts/run_chXX.sh`의 기본 `DUT_PATH`는 `reference_rtl/`을 사용.
- `amd_soc_rtl/system_verilog_uvm_tb/`는 이전에 잘못 작성된 사본이며 앞으로 신규 작업 대상이 아님.

## 제08장 · 객체와 제약 기반 입력
- **DUT:** `reference_rtl/uart_echo_controller.v`, 원본 Blob SHA `28160c34522e47fbd961466651598da063bc74ae`.
- **포트 계약:** `rx_data_i→tx_data_o`, `rx_valid_i→tx_valid_o`, `tx_ready_i→rx_ready_o`. 클록·리셋 없는 조합회로.
- **신규 파일:** `tb/ch08/tb_uart_objects.sv`, `scripts/run_ch08.sh`, `ch08_objects_constraints_v01.html`.
- **검증 내용:** class/new, 상속, rand, printable ASCII 제약, 인라인 IDLE 제약, STALL 제약, 4상태 출력 비교 및 4회 검사.
- **실행 상태:** RTL_SIM=NOT_RUN (작성 환경에 Verilator 없음). 예상 출력은 무작위 바이트 예시이며 실제 로그 아님.
- **정적 검토:** 파일 존재, DUT 실제 6포트, 코드/도식 신호, HTML 상대 링크, 좌측 PART02→CH08→SECTION 구조 소스 점검. 실브라우저 렌더링은 NOT_RUN.
- **규칙:** `Yuul-Jung/rule_md`의 AGENTS.md, HTML STANDARD, code-development-rules, code-style-rules, flowchart-rules를 읽고 반영.

## 제09장 · 참조 모델·스코어보드
- **검증 DUT:** `reference_rtl/pwm_core.v` (원본 Blob SHA `e813f3fb107bd327054d11e0b397817b8e7bd813`), 읽기 전용.
- **참조 모델:** `tb/ch09/pwm_reference_model.sv`; DUT 내부 신호를 사용하지 않는 별도 `phase`, `queued_*`, `ref_*` 상태.
- **테스트벤치:** `tb/ch09/tb_pwm_scoreboard.sv`; DUT의 `pwm_out/pending/active_period/active_duty/active_enable/active_polarity`를 매 상승 에지 `#1` 후 참조값과 비교.
- **실행 스크립트:** `scripts/run_ch09.sh` (`iverilog -g2012` + `vvp`, `.build/ch09/` 출력).
- **발행 HTML:** `ch09_reference_model_scoreboard_v02.html`.
- **시나리오:** 25% → 75% → 주기 경계/Apply 겹침 → 반전 → 출력 차단 → 100% → 동작 중 리셋 → 0%. 여섯 `cfg_apply` 요청.
- **클록·리셋:** `RESET_PERIOD=8`, 10ns 클록, 내부 레지스터는 posedge 동기 리셋, `pwm_out`은 resetn의 조합 게이팅.
- **검증 상태:** GitHub 파일·포트·INDEX 정적 검증 완료, RTL_SIM **NOT_RUN**. 예상 결과는 실제 로그 아님.

- **제09장 검증 근거:** `docs/CH09_VALIDATION_v02.md`. 이론상 score_cycles=72이나 실제 RTL_SIM은 NOT_RUN.

## 제10장 · 경계조건·오류 주입과 검출
- **검증 DUT:** `reference_rtl/pwm_core.v`, 원본 Blob SHA `e813f3fb107bd327054d11e0b397817b8e7bd813`. DUT 파일은 읽기 전용.
- **배포 페이지:** `ch10_corner_reset_timeout_v02.html`.
- **TB:** `tb/ch10/tb_pwm_corner_reset_timeout.sv`. DUT의 실제 7개 입력·6개 출력 포트를 원본 이름으로 연결.
- **정상 시나리오:** `RESET_PERIOD=8`, 주기 8클록, 0% LOW 16번, 100% HIGH 16번, 중간 LOW 리셋→재설정 HIGH 16번, 총 48회 출력 검사.
- **오류 주입 A:** `+INJECT_FAULT`는 검증기 측 `measured_pwm` 값만 반전하여 `DETECTED_INJECTED_FAULT`를 기대.
- **오류 주입 B:** `+INJECT_TIMEOUT`은 TB 외부 입력의 듀티 8 `cfg_apply`를 누락하여 10클록 내 Active 적용 실패 `DETECTED_APPLY_TIMEOUT` 기대.
- **검증 스크립트:** `scripts/run_ch10.sh`는 정상 시뮬레이션 종료 코드 0 및 48회 PASS 확인 후, 두 부정 시험이 정확한 이유로 비정상 종료한 것을 확인해야 성공한다.
- **파형·로그:** `.build/ch10/normal.log`, `fault_injection.log`, `apply_timeout.log`; 사용 가능 시 각 `.vcd` 분리 기록.
- **제작 검증:** 정적 소스/문서/포트/링크 분석 완료, 실제 RTL_SIM=NOT_RUN. 근거는 `docs/CH10_VALIDATION_v02.md`.

## 제13장 · UART 스트림 검증
- DUT: reference_rtl/uart_echo_controller.v (Blob 28160c34522e47fbd961466651598da063bc74ae), 원본 변경 없음.
- TB: tb/ch13/tb_uart_stream.sv; 스크립트: scripts/run_ch13.sh; HTML: ch13_uart_stream_verification_v01.html.
- 조합 6포트 검증, TB 가상 샘플 클록 10ns, 프레임은 바이트 시퀀스. 실제 직렬 UART 프레이밍 검증은 해당 없음.
- RTL_SIM NOT_RUN, BROWSER_VISUAL NOT_RUN; 상세: docs/CH13_VALIDATION_v01.md.

## 제14장 · FIFO 및 흐름 제어
- 원본: amd_soc_rtl/part03/common/rtl/{uart_core.v,uart_rx.v,uart_tx.v}; 바이트 동일 사본은 reference_rtl/에 보관.
- 원본 Blob: 5390c312b186c27abb2b2818f76ec76d164c75f1, f0d2f9fcdf84aec913720103fb373738417bf7d1, dfcb0cf10293a2a66ab7d704621a5219144673eb.
- TB: tb/ch14/tb_uart_fifo_flow.sv; 스크립트: scripts/run_ch14.sh; HTML: ch14_fifo_flow_control_v01.html.
- 실제 UART 직렬 TX/RX 및 16바이트 FIFO 포트 검증. RTL_SIM NOT_RUN, BROWSER_VISUAL NOT_RUN.

## 제15장 · AXI4-Lite 레지스터 검증
- DUT: reference_rtl/axi4lite_slave_adapter.v (Blob eadaf8d3580023bed0c9b06f3e9b2a99de0cf266), reference_rtl/custom_register_bank.v (Blob 49e5d0219574d1bcb9086dc99f259c191e35d82e), 원본과 바이트 동일.
- TB: tb/ch15/tb_axi4lite_registers.sv; script: scripts/run_ch15.sh; HTML: ch15_axi4lite_register_verification_v01.html.
- RTL_SIM NOT_RUN, BROWSER_VISUAL NOT_RUN. 상세: docs/CH15_VALIDATION_v01.md.

## 제16장 · MAC·NPU 정수 연산 검증
- 원본: amd_soc_rtl/part03/ch01/rtl/mac_core.v (Blob d3f911b882f65e8f6096d76d31a2b710c18ae38d); part03/ch03/rtl/mac_pipeline_core.v (Blob f690b2db2a16626a43e0bb9f3c859d616e57116d).
- 바이트 동일 DUT 사본: reference_rtl/mac_core.v, reference_rtl/mac_pipeline_core.v.
- TB: tb/ch16/tb_mac_integer.sv; Python: scripts/ch16_reference.py; 실행: scripts/run_ch16.sh.
- HTML: ch16_mac_npu_integer_verification_v01.html; RTL_SIM NOT_RUN, BROWSER_VISUAL NOT_RUN.

## 제17장 · 최소 UVM 환경
- DUT: reference_rtl/pwm_core.v (Blob e813f3fb107bd327054d11e0b397817b8e7bd813), 원본 수정 없음.
- TB: tb/ch17/tb_pwm_uvm.sv; script: scripts/run_ch17.sh; HTML: ch17_minimal_uvm_environment_v01.html.
- RTL_SIM NOT_RUN / BROWSER_VISUAL NOT_RUN; 상세: docs/CH17_VALIDATION_v01.md.

## 제18장 · Sequence에서 Driver까지
- DUT: reference_rtl/pwm_core.v (Blob e813f3fb107bd327054d11e0b397817b8e7bd813), 원본 변경 없음.
- TB: tb/ch18/tb_pwm_sequence_driver.sv; 실행: scripts/run_ch18.sh; HTML: ch18_sequence_driver_v01.html.
- 정적 점검: PART05→CH18→SECTION, 포트·신호·목차·상대 링크.
- RTL_SIM NOT_RUN; BROWSER_VISUAL NOT_RUN. 자세한 내용: docs/CH18_VALIDATION_v01.md.

## 제19장 · Monitor·Agent·Scoreboard
- **기준 저장소:** `Yuul-Jung/system_verilog_uvm_tb` 루트.
- **DUT:** `reference_rtl/pwm_core.v`, 원본 Blob SHA `e813f3fb107bd327054d11e0b397817b8e7bd813`. 원본 변경 없음.
- **TB:** `tb/ch19/tb_pwm_monitor_agent_scoreboard.sv` (interface `pwm19_if`, Sequence·Sequencer·Driver·Monitor·Agent·Environment·Scoreboard·Test).
- **실습:** 요청 듀티 2→6→0을 제18장과 같은 순서로 진행한다. `pwm19_monitor`는 `PWM19_REQUEST`/ `PWM19_APPLIED` 이벤트를 관찰하여 `ap.write()`로 보낸다.
- **독립 판정:** `pwm19_scoreboard`는 고정된 `planned_duty[3]`와 요청·적용 관찰을 비교하고, 80ns의 적용 시간 한계·출력 조건을 확인한다. DUT 내부 hierarchical path를 사용하지 않는다.
- **연결:** `pwm19_agent`가 `sqr`·`drv`·`mon`을 생성하고, `pwm19_env`가 `ag.mon.ap.connect(sb.analysis_export)`를 수행한다.
- **실행:** `scripts/run_ch19.sh` (Verilator + UVM_HOME, `--binary --timing --assert --trace`).
- **HTML:** `ch19_monitor_agent_scoreboard_v02.html` · 검증 기록 `docs/CH19_VALIDATION_v02.md`.
- **범위 제한:** 현재 3개 입력은 순차 제출된다. 같은 설정 반복·동시 Apply/Boundary·중간 리셋까지 일반화하지 않았다.
- **검증 상태:** 정적 검토 완료, 실제 RTL_SIM=NOT_RUN, 실제 브라우저/Pages 접속=NOT_RUN.

## 제20장 · Factory·Config·Objection
- **독립 저장소:** `Yuul-Jung/system_verilog_uvm_tb` 루트.
- **원본 DUT:** `reference_rtl/pwm_core.v`, Git Blob `e813f3fb107bd327054d11e0b397817b8e7bd813`, 수정 없음.
- **배포 페이지:** `ch20_factory_config_objection_v01.html`.
- **TB:** `tb/ch20/tb_pwm_factory_config_objection.sv`; `pwm20_if`, `pwm20_cfg`, `pwm20_item`, `pwm20_sequence`, `pwm20_driver`, `pwm20_traced_driver`, `pwm20_monitor`, `pwm20_scoreboard`, `pwm20_agent`, `pwm20_env`, `pwm20_test`.
- **Factory:** `pwm20_test.build_phase()`가 `pwm20_driver` → `pwm20_traced_driver` 타입 교체를 env 생성 전에 등록; `$cast`로 실제 타입을 확인.
- **Config DB:** `pwm20_cfg`의 `duty_plan={2,6,0}`, `max_wait_cycles=12`, `max_apply_ns=80`, `expected_transactions=3` 공유.
- **Objection:** `run_phase` 진입 시 raise, 3개 실제 Driver 거래와 Monitor/Scoreboard의 REQUEST/APPLIED 및 추적 카운트 확인 후 drop.
- **실행 스크립트:** `scripts/run_ch20.sh` (Verilator+UVM_HOME, `--binary --timing --assert --trace`).
- **검증 범위:** 단계적인 PWM 설정 3회, 이벤트 순서 및 구성 재사용. 중첩 적용 요청·다중 Agent·진정한 랜덤 시퀀스는 본 장 범위 제외.
- **실행 결과:** RTL_SIM=NOT_RUN, BROWSER_VISUAL=NOT_RUN, PAGES_HTTP=NOT_RUN. 자세한 내용은 `docs/CH20_VALIDATION_v01.md`.

## 제21장 · UVM 레지스터 추상화
- DUT: reference_rtl/axi4lite_slave_adapter.v (Blob eadaf8d3580023bed0c9b06f3e9b2a99de0cf266), reference_rtl/custom_register_bank.v (Blob 49e5d0219574d1bcb9086dc99f259c191e35d82e); 원본 변경 없음.
- TB: tb/ch21/tb_axi_uvm_ral.sv; 실행: scripts/run_ch21.sh; HTML: ch21_uvm_register_abstraction_v01.html.
- RAL 4개 레지스터, Adapter, 완료 거래 기반 Predictor; 독립 AXI Monitor는 후속 확장.
- RTL_SIM NOT_RUN, BROWSER_VISUAL NOT_RUN. docs/CH21_VALIDATION_v01.md.

## 제22장 · 다중 Agent·VIP
- **독립 저장소:** `Yuul-Jung/system_verilog_uvm_tb` 루트.
- **원본 RTL:** `reference_rtl/axi4lite_slave_adapter.v` (Blob `eadaf8d3580023bed0c9b06f3e9b2a99de0cf266`), `reference_rtl/custom_register_bank.v` (Blob `49e5d0219574d1bcb9086dc99f259c191e35d82e`). 변경 없음.
- **배포 HTML:** `ch22_multi_agent_vip_v02.html`. 소스: `tb/ch22/tb_axi_multiagent_irq.sv`. 실행: `scripts/run_ch22.sh`.
- **AXI Agent:** `axi22_bus_agent` 아래 Sequencer·Master Driver·독립 AXI Handshake Monitor. B/R Backpressure 2클록 확인.
- **IRQ Agent:** `irq22_event_agent`가 resetn, irq_done_event_i, irq_error_event_i를 구동하고 실제 irq_status_o를 관찰.
- **Virtual Sequence:** `axi22_system_sequence`가 `axi22_virtual_sequencer`의 bus_sqr/evt_sqr 두 하위 Sequencer를 조정.
- **Scoreboard:** `uvm_analysis_imp_bus`·`uvm_analysis_imp_irq` 두 경로로 실제 AXI 거래와 하드웨어 이벤트를 받아 CONTROL/DATA_IN/IRQ_STATUS/W1C/RO 값을 검증.
- **시나리오:** 정상 AXI W=4 / R=11, 하드웨어 IRQ=2, 리셋 관찰=2. AW/W 독립 수락·B/R 유지 검증. 동시 다중 Master 및 상용 AMD AXI VIP 직접 연동은 범위 제외.
- **검증 상태:** UVM Config DB 범위 오류 수정, 정적 검사 및 목차 연결 확인. RTL_SIM=NOT_RUN, BROWSER_VISUAL=NOT_RUN, PAGES_HTTP=NOT_RUN. `docs/CH22_VALIDATION_v01.md` 참고.

- **제22장 교정:** 최상위 Test·하위 Agent를 모두 포함하도록 가상 Interface Config DB 경로를 `uvm_test_top*`로 수정. HTML v02의 코드·구조도 함께 갱신.

## 제24장 · 회귀·CI·검증 보고
- DUT: reference_rtl/uart_echo_controller.v (Blob 28160c34522e47fbd961466651598da063bc74ae); 원본 변경 없음.
- TB: tb/ch24/tb_uart_regression.sv; 실행: scripts/run_ch24.py, scripts/run_ch24.sh; CI: .github/workflows/ch24-regression.yml.
- HTML: ch24_regression_ci_reporting_v01.html; 기록: docs/CH24_VALIDATION_v01.md.
- 시드 1/7/42, 각 32건, 4개 상태, 음성 시험, JSON/Markdown 보고. RTL_SIM NOT_RUN, CI_RUN NOT_RUN, BROWSER_VISUAL NOT_RUN.

## 제01장 v02 · 학습안내서 개정
- ch01_testbench_basics_v02.html: 원본 RTL·TB 전체 코드, SVG 도식·예상 파형, XSIM 절차 추가. RTL/TB 변경 없음.
- [검증 기록](docs/CH01_VALIDATION_v02.md). RTL_SIM/BROWSER: NOT_RUN.

## 제01장 v03 · 독립 배포 및 도식 수정
- ch01_testbench_basics_v03.html: 학생 본문에 원본 RTL/TB 전체 코드와 실행 경로 제공, 외부 원본 링크·SHA 제거, 실제 6포트 연결도 수정.
- [검증 기록](docs/CH01_VALIDATION_v03.md). 수정 SVG 단독 Chromium 렌더링 및 좌표 확인, RTL_SIM/전체 페이지 렌더링 NOT_RUN.

## 제02장 v02 · 설계 연계 및 관찰 환경 보완
- amd_soc_npu 제2부 04.2장 02·06절과 원본 PWM 일치. DUT 수정 없음. TB 시간 표시와 VCD 조건부 기록 보완.
- ch02_clock_reset_events_v02.html; [검증 기록](docs/CH02_VALIDATION_v02.md). 예상 상태 계산/두 SVG 단독 렌더링 완료, RTL_SIM 및 전체 페이지 렌더링 NOT_RUN.
