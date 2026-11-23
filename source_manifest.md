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
- 정본 저장 위치: `Yuul-Jung/system_velirog_uvm_tb/`의 루트.
- 원본 스냅샷: `reference_rtl/uart_echo_controller.v` (Blob `28160c34522e47fbd961466651598da063bc74ae`), `reference_rtl/pwm_core.v` (Blob `e813f3fb107bd327054d11e0b397817b8e7bd813`).
- 두 RTL 파일은 원본과 바이트 단위로 동일하게 보존하며 `scripts/run_chXX.sh`의 기본 `DUT_PATH`는 `reference_rtl/`을 사용.
- `amd_soc_rtl/system_verilog_uvm_tb/`는 이전에 잘못 작성된 사본이며 앞으로 신규 작업 대상이 아님.
