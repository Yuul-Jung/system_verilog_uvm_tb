# RTL Testbench · SystemVerilog · UVM 검증 학습안내서

- **교육과정:** 6부 24장. 기존 RTL을 보존하고 독립 테스트벤치로 검증합니다.
- **진입점:** [전체 학습안내서](index.html) · [전체 편성](CURRICULUM.md) · [설계 대응표](docs/DESIGN_VERIFICATION_MAP.md)
- **검증 상태:** 24장 실제 실행 완료(관찰 3장·자동 PASS 21장), 부정 시험 12건 검출. [v59 공개 증거](docs/evidence/v59/README.md)와 [종합 보고서](docs/COURSE_VALIDATION_v03.md)에서 확인합니다. v60에서 제11·14·23장 TB와 실행 스크립트를 고친 내역과 재실행 범위는 [실행 후 변경 기록](docs/evidence/POST_RUN_CHANGES_v59.md)에 있습니다(제11장 개정 TB는 XSIM 2024.2로 재실행 PASS).

## 최신 장별 자료

| 부 | 장 | 학습안내서 | 테스트벤치 |
|---|---:|---|---|
| 1 | 01 | [테스트벤치의 첫 실행](ch01_testbench_basics_v05.html) | [tb/ch01/tb_uart_echo_basics.sv](tb/ch01/tb_uart_echo_basics.sv) |
| 1 | 02 | [Clock·Reset·이벤트](ch02_clock_reset_events_v04.html) | [tb/ch02/tb_pwm_clock_reset.sv](tb/ch02/tb_pwm_clock_reset.sv) |
| 1 | 03 | [반복 자극과 작업 분리](ch03_reusable_stimulus_v04.html) | [tb/ch03/tb_pwm_reusable_stimulus.sv](tb/ch03/tb_pwm_reusable_stimulus.sv) |
| 1 | 04 | [PASS/FAIL 자동 판정](ch04_pass_fail_automation_v05.html) | [tb/ch04/tb_pwm_pass_fail.sv](tb/ch04/tb_pwm_pass_fail.sv) |
| 2 | 05 | [검증 자료형과 타입](ch05_verification_types_v05.html) | [tb/ch05/tb_uart_types.sv](tb/ch05/tb_uart_types.sv) |
| 2 | 06 | [배열·큐·패키지](ch06_arrays_queues_packages_v05.html) | [tb/ch06/tb_uart_arrays_queues.sv](tb/ch06/tb_uart_arrays_queues.sv) |
| 2 | 07 | [인터페이스·타이밍 분리](ch07_interface_modport_clocking_v04.html) | [tb/ch07/tb_uart_interface.sv](tb/ch07/tb_uart_interface.sv) |
| 2 | 08 | [객체와 제약 기반 입력](ch08_objects_constraints_v04.html) | [tb/ch08/tb_uart_objects.sv](tb/ch08/tb_uart_objects.sv) |
| 3 | 09 | [참조 모델·스코어보드](ch09_reference_model_scoreboard_v04.html) | [tb/ch09/tb_pwm_scoreboard.sv](tb/ch09/tb_pwm_scoreboard.sv) |
| 3 | 10 | [경계조건·오류 주입](ch10_corner_reset_timeout_v05.html) | [tb/ch10/tb_pwm_corner_reset_timeout.sv](tb/ch10/tb_pwm_corner_reset_timeout.sv) |
| 3 | 11 | [시간적 속성 검사](ch11_temporal_assertions_v05.html) | [tb/ch11/tb_pwm_sva.sv](tb/ch11/tb_pwm_sva.sv) |
| 3 | 12 | [기능 커버리지](ch12_functional_coverage_v03.html) | [tb/ch12/tb_pwm_coverage.sv](tb/ch12/tb_pwm_coverage.sv) |
| 4 | 13 | [UART 스트림 검증](ch13_uart_stream_verification_v03.html) | [tb/ch13/tb_uart_stream.sv](tb/ch13/tb_uart_stream.sv) |
| 4 | 14 | [FIFO 및 흐름 제어](ch14_fifo_flow_control_v04.html) | [tb/ch14/tb_uart_fifo_flow.sv](tb/ch14/tb_uart_fifo_flow.sv) |
| 4 | 15 | [AXI4-Lite 레지스터 검증](ch15_axi4lite_register_verification_v03.html) | [tb/ch15/tb_axi4lite_registers.sv](tb/ch15/tb_axi4lite_registers.sv) |
| 4 | 16 | [MAC·NPU 정수 연산 검증](ch16_mac_npu_integer_verification_v03.html) | [tb/ch16/tb_mac_integer.sv](tb/ch16/tb_mac_integer.sv) |
| 5 | 17 | [최소 UVM 환경](ch17_minimal_uvm_environment_v04.html) | [tb/ch17/tb_pwm_uvm.sv](tb/ch17/tb_pwm_uvm.sv) |
| 5 | 18 | [Sequence에서 Driver까지](ch18_sequence_driver_v04.html) | [tb/ch18/tb_pwm_sequence_driver.sv](tb/ch18/tb_pwm_sequence_driver.sv) |
| 5 | 19 | [Monitor·Agent·Scoreboard](ch19_monitor_agent_scoreboard_v05.html) | [tb/ch19/tb_pwm_monitor_agent_scoreboard.sv](tb/ch19/tb_pwm_monitor_agent_scoreboard.sv) |
| 5 | 20 | [Factory·Config·Objection](ch20_factory_config_objection_v04.html) | [tb/ch20/tb_pwm_factory_config_objection.sv](tb/ch20/tb_pwm_factory_config_objection.sv) |
| 6 | 21 | [UVM 레지스터 추상화](ch21_uvm_register_abstraction_v04.html) | [tb/ch21/tb_axi_uvm_ral.sv](tb/ch21/tb_axi_uvm_ral.sv) |
| 6 | 22 | [다중 Agent·VIP](ch22_multi_agent_vip_v05.html) | [tb/ch22/tb_axi_multiagent_irq.sv](tb/ch22/tb_axi_multiagent_irq.sv) |
| 6 | 23 | [NPU 통합 정답 비교](ch23_npu_integrated_scoreboard_v05.html) | [tb/ch23/tb_npu_integrated.sv](tb/ch23/tb_npu_integrated.sv) |
| 6 | 24 | [회귀·CI·검증 보고](ch24_regression_ci_reporting_v04.html) | [tb/ch24/tb_uart_regression.sv](tb/ch24/tb_uart_regression.sv) |

## Ubuntu 실습 시작

```bash
# 독립 저장소를 복제하고 작업 폴더로 진입한다.
git clone https://github.com/Yuul-Jung/system_verilog_uvm_tb.git
cd system_verilog_uvm_tb
# 시스템 Icarus가 없다면 배포판 패키지로 설치한다.
sudo apt update
sudo apt install -y iverilog g++ make git
# Vivado 설치는 변경하지 않고, Verilator 5.054와 Z3는 저장소의
# .tools/ 아래에만 설치한다. 이미 설치되어 있으면 즉시 종료한다.
bash scripts/bootstrap_local_tools.sh
source scripts/setup_env.sh
# 제1장 예제 실행
bash scripts/run_ch01.sh
# 제24장 독립 회귀 예제 실행
bash scripts/run_ch24.sh
```

Vivado XSIM/UVM 등이 필요한 장은 해당 학습안내서의 환경 준비와 실행 명령을 따른다. 이전 상세 변경 이력은 Git 기록으로 보존한다.

## 제작·검증 원칙

- [중앙 rule_md](https://github.com/Yuul-Jung/rule_md) · [과정 규칙](AGENTS.md)
- 순서화 → 구조화 → 체계화 → 시각화. 원본 RTL과 TB, 예상 출력과 실측을 구별합니다.
- Ubuntu에서 저장소를 복제한 뒤 장별 안내서의 실행 절차를 따릅니다. Vivado XSIM/UVM과 Icarus/Verilator 지원 범위는 장별로 다릅니다.
- 생성 로그는 `.build/`에 보관합니다. 원본 RTL 수정 금지. 제24장은 UART Echo 단일 DUT의 회귀 예제이며 전 과정 CI가 아닙니다.
- [통합 적대적 검증 기록](docs/COURSE_VALIDATION_v03.md)
