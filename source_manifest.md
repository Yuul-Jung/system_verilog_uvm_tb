# Source Manifest · 현행 v60

기준일: 2026-11-26 KST. 이 문서는 현재 발행본·실행 경로·소스 해시의 정본이다. 과거 제작 당시의 NOT_RUN과 도구 설명은 [이전 기록](docs/SOURCE_MANIFEST_HISTORY_v58.md)에 분리했다.

- 과정: `system_verilog_uvm_tb`, 6부 24장, `course.json` v60.
- 기준 저장소 커밋: `10d0ec00ecffca46aa49f88704f2782982ec7fc5` 위에서 수정 후 실제 실행. 실행 당시 파일 바이트는 증거 manifest의 SHA256으로 특정한다.
- 규칙: `rule_md` @ `028248a19afc66e9aafdab393fbe0de10a3930ca` 및 과정 AGENTS.md.
- 원본 RTL: 변경 없음.
- v60 교정(2026-11-26 독립 적대적 검증 반영): 제11·14·23장 TB에 결함 검출 시험을 추가하고 각각 v05·v04·v05로 발행했다. `run_chapter.sh`는 Vivado가 없어도 Icarus·Verilator 장을 실행하며, `bootstrap_local_tools.sh`는 내려받은 `help2man`이 쓰는 Perl 모듈 경로를 설정한다. 증거 검사기는 Verilator 오류 형식, 완료 행 1회, SHA256SUMS를 추가로 대조한다.
- v59 증거는 실행 당시 소스와 짝을 이루므로 그대로 보존한다. 실행 이후 바뀐 파일과 재실행 범위는 [실행 후 변경 기록](docs/evidence/POST_RUN_CHANGES_v59.md)에 있다. 제14·23장은 같은 도구(Icarus 12.0)로 다시 PASS했고, 제11장 개정 TB는 Verilator 5.054로만 확인했다(**XSIM NOT_RUN**).
- [공개 실행 증거](docs/evidence/v59/README.md) · [기계 판독 manifest](docs/evidence/v59/manifest.json) · [종합 검증 보고서](docs/COURSE_VALIDATION_v03.md).

## 현재 실행 환경과 경로

- Icarus Verilog 12.0: 제01~06·09~10·13~16·23~24장.
- Verilator 5.054: 제07~08장. 제08장 제약 해결기는 Z3 4.8.12.
- Vivado XSIM 2024.2: 제11~12·17~22장. 제12장 xcrg 기능 커버리지 보고서 생성 완료.
- 공통 실행: `bash scripts/run_chapter.sh NN`. 01~24를 검증하고 제11·12장을 실제 `tb/chNN/run_chNN.sh`로 분기한다.
- VS Code task는 Bash와 이 공통 실행기를 사용한다. `settings64.sh` 설정은 기존 설치에서 읽으며 로컬 대체 도구는 `.tools/`에서 활성화한다.

| 장 | 발행본 | 주 TB | 실제 장별 실행기 | 실행 판정 / 종료 코드 |
|---:|---|---|---|---|
| 01 | [v05](ch01_testbench_basics_v05.html) | `tb/ch01/tb_uart_echo_basics.sv` | `scripts/run_ch01.sh` | EXECUTED_OBSERVATION / 0 |
| 02 | [v04](ch02_clock_reset_events_v04.html) | `tb/ch02/tb_pwm_clock_reset.sv` | `scripts/run_ch02.sh` | EXECUTED_OBSERVATION / 0 |
| 03 | [v04](ch03_reusable_stimulus_v04.html) | `tb/ch03/tb_pwm_reusable_stimulus.sv` | `scripts/run_ch03.sh` | EXECUTED_OBSERVATION / 0 |
| 04 | [v05](ch04_pass_fail_automation_v05.html) | `tb/ch04/tb_pwm_pass_fail.sv` | `scripts/run_ch04.sh` | PASS / 0 |
| 05 | [v05](ch05_verification_types_v05.html) | `tb/ch05/tb_uart_types.sv` | `scripts/run_ch05.sh` | PASS / 0 |
| 06 | [v05](ch06_arrays_queues_packages_v05.html) | `tb/ch06/tb_uart_arrays_queues.sv` | `scripts/run_ch06.sh` | PASS / 0 |
| 07 | [v04](ch07_interface_modport_clocking_v04.html) | `tb/ch07/tb_uart_interface.sv` | `scripts/run_ch07.sh` | PASS / 0 |
| 08 | [v04](ch08_objects_constraints_v04.html) | `tb/ch08/tb_uart_objects.sv` | `scripts/run_ch08.sh` | PASS / 0 |
| 09 | [v04](ch09_reference_model_scoreboard_v04.html) | `tb/ch09/tb_pwm_scoreboard.sv` | `scripts/run_ch09.sh` | PASS / 0 |
| 10 | [v05](ch10_corner_reset_timeout_v05.html) | `tb/ch10/tb_pwm_corner_reset_timeout.sv` | `scripts/run_ch10.sh` | PASS / 0 |
| 11 | [v05](ch11_temporal_assertions_v05.html) | `tb/ch11/tb_pwm_sva.sv` | `tb/ch11/run_ch11.sh` | 이전 TB XSIM PASS / 0 · 개정 TB Verilator PASS · XSIM NOT_RUN |
| 12 | [v03](ch12_functional_coverage_v03.html) | `tb/ch12/tb_pwm_coverage.sv` | `tb/ch12/run_ch12.sh` | PASS / 0 |
| 13 | [v03](ch13_uart_stream_verification_v03.html) | `tb/ch13/tb_uart_stream.sv` | `scripts/run_ch13.sh` | PASS / 0 |
| 14 | [v04](ch14_fifo_flow_control_v04.html) | `tb/ch14/tb_uart_fifo_flow.sv` | `scripts/run_ch14.sh` | PASS / 0 (개정 TB 재실행) |
| 15 | [v03](ch15_axi4lite_register_verification_v03.html) | `tb/ch15/tb_axi4lite_registers.sv` | `scripts/run_ch15.sh` | PASS / 0 |
| 16 | [v03](ch16_mac_npu_integer_verification_v03.html) | `tb/ch16/tb_mac_integer.sv` | `scripts/run_ch16.sh` | PASS / 0 |
| 17 | [v04](ch17_minimal_uvm_environment_v04.html) | `tb/ch17/tb_pwm_uvm.sv` | `scripts/run_ch17.sh` | PASS / 0 |
| 18 | [v04](ch18_sequence_driver_v04.html) | `tb/ch18/tb_pwm_sequence_driver.sv` | `scripts/run_ch18.sh` | PASS / 0 |
| 19 | [v05](ch19_monitor_agent_scoreboard_v05.html) | `tb/ch19/tb_pwm_monitor_agent_scoreboard.sv` | `scripts/run_ch19.sh` | PASS / 0 |
| 20 | [v04](ch20_factory_config_objection_v04.html) | `tb/ch20/tb_pwm_factory_config_objection.sv` | `scripts/run_ch20.sh` | PASS / 0 |
| 21 | [v04](ch21_uvm_register_abstraction_v04.html) | `tb/ch21/tb_axi_uvm_ral.sv` | `scripts/run_ch21.sh` | PASS / 0 |
| 22 | [v05](ch22_multi_agent_vip_v05.html) | `tb/ch22/tb_axi_multiagent_irq.sv` | `scripts/run_ch22.sh` | PASS / 0 |
| 23 | [v05](ch23_npu_integrated_scoreboard_v05.html) | `tb/ch23/tb_npu_integrated.sv` | `scripts/run_ch23.sh` | PASS / 0 (개정 TB 재실행) |
| 24 | [v04](ch24_regression_ci_reporting_v04.html) | `tb/ch24/tb_uart_regression.sv` | `scripts/run_ch24.sh` | PASS / 0 |

제01~03장은 자동 정오 판정 없이 실행·관찰을 완료했다. 나머지 21장은 자동 판정 PASS다. 별도 부정 시험 12건은 전용 진단과 개별 종료 코드를 공개 증거에 기록했다.

## 현행 검증 계약

- UART Echo(01·05~08·13·24): 클록 없는 6포트 조합 전달. 제07장 tb_clk는 검증 기준 클록이며 DUT 클록이 아니다. 제13장은 바이트 스트림, 제14장은 실제 직렬 UART와 FIFO 검증이다.
- PWM(02~04·09~12·17~20): Shadow 설정과 주기 경계 Active 반영, 동기 레지스터 리셋 및 비동기적 출력 게이팅을 구분한다. 제19·20장 Monitor의 31개 비리셋 표본과 3개 리셋 표본 중 활성 출력 표본은 24개다.
- CH21 RAL: `axi21_monitor`가 실제 B/R 완료 거래를 독립 관찰한다. `uvm_reg_predictor`로 Mirror를 갱신하고 `set_auto_predict(0)`을 사용한다. reads=7, writes=3, 총 10거래다.
- CH22 다중 Agent: AXI W=6, R=13, 총 19거래, IRQ=4, RESET=2, COLLISION=1, ZERO=1이다. 실제 bank commit=6과 이벤트 set/W1C 동시 우선순위를 검증한다.
- CH23 NPU: 배포 스냅샷의 지연은 `2*length+2`이고 8개 연산 및 4개 거부를 실행했다. 현행 외부 엔진의 CMP1/CMP2 계약과 섞지 않는다.
- CH24: UART Echo 하나의 세 시드 회귀와 오류 주입이다. 전 과정 원격 CI 결과를 의미하지 않는다.

## 배포 RTL의 SHA256

아래는 이번 실행 당시 파일 바이트의 SHA256이다. 출처 Git Blob SHA 및 현행 설계와의 관계는 [설계 대응표](docs/DESIGN_VERIFICATION_MAP.md)에 보존한다.

| 파일 | SHA256 |
|---|---|
| `reference_rtl/axi4lite_slave_adapter.v` | `1fa68691b1e084bfc0106e2b8cc4176c34f453fb9c7e3a03445c73f55455dae1` |
| `reference_rtl/custom_register_bank.v` | `8ab6ad93899d148d7dbf3d8ac965d0826f52a29e4f501616221ad7b0aab9d7a7` |
| `reference_rtl/dsp_multiplier.v` | `48d1d35c2add3d0fccaf92c1917079873344320e23d0718e43539d13033f8093` |
| `reference_rtl/mac_core.v` | `32e11915722acf1028e2bf3cccc5b10d8f525a85b1731f92f821d73122a09857` |
| `reference_rtl/mac_pipeline_core.v` | `9e05b10ee7cf55f3ef46b02ab920ad688504561929576fa8ab50acd6bc57c1f1` |
| `reference_rtl/npu_dsp_mac_lane.v` | `ffcadb6575ba84c7c6f32acf7d3860a2d25617946859da6dbd8582f1fcd3d4f5` |
| `reference_rtl/npu_engine4.v` | `6469feff2d0686be890be33655170aab73e0a556d91c8f30e9d6e7657eeb3438` |
| `reference_rtl/pwm_core.v` | `b375e18220be7b06ac421a2b7076af5a88d34a7846c7bf4b0b266bab189050f4` |
| `reference_rtl/uart_core.v` | `b5f3cb2825797958aca3c9a3f97b6425f339f46a216cca41cfd49f318eee9683` |
| `reference_rtl/uart_echo_controller.v` | `3eaed301742a18b8e8652e3f73fb87da9b7635b59a557ed07429d0481de7d0ef` |
| `reference_rtl/uart_rx.v` | `b4aff65d44e8749eacd001a15141d52e42fde9878b32553f3c6d5359a1c4609a` |
| `reference_rtl/uart_tx.v` | `2a5b7586e775cec77df708156ac4717ff5bca2a9b0352568121934f4fbafaa5b` |

## 상태와 검증 범위

- 로컬 24장 실행과 12개 부정 시험: 실제 수행, 공개 로그와 해시 보존.
- 브라우저: 표준 6개 폭과 29개 SVG, 모바일·키보드·복사 검증은 종합 보고서의 최종 결과를 기준으로 한다.
- 원격 Actions: `CH24 UART regression` 워크플로가 4회 실행되어 모두 성공했다(마지막 실행은 ch24 최신 변경 커밋 `e3f84a5`). 다른 장은 원격 CI 대상이 아니다. 공개 Pages: 최신·구버전 HTML 및 핵심 증거 103개 HTTP 200/SHA256 일치 확인. [원격 검증 기록](docs/REMOTE_VERIFICATION_v59.json)을 참조한다.
- 과거 기록은 당시 상태를 보존하는 자료이며 이 현행 표를 덮어쓰지 않는다.
