# v59 공개 실행 증거

2026-11-26 KST에 24장을 순차 실행했다. 기준 커밋 `10d0ec00ecffca46aa49f88704f2782982ec7fc5`과 실행 당시 [소스 SHA256·명령·종료 코드·전체 로그 해시](manifest.json)를 함께 확인한다. 수정된 파일의 정확한 바이트는 manifest의 `sources_sha256`이 식별한다.

```bash
python3 scripts/collect_evidence.py --verify
cd docs/evidence/v59
sha256sum -c SHA256SUMS
```

- `runs/`: 이번 실제 실행의 공개 로그. `runner.txt`에는 shell이 실행한 명령과 출력이 함께 있다.
- `legacy/`: 재실행 전 .build에서 추출한 로그. 당시 미기록 종료 코드는 `NOT_RECORDED`로 남기고 이번 실행 코드와 혼동하지 않는다.
- `probes/`: 보존된 빌드로 별도 재측정한 12개 부정 시험. XSIM의 UVM_FATAL/SVA는 이 버전에서 exit=0일 수 있으므로 전용 진단과 정상 PASS 부재를 함께 검사한다.
- raw_sha256은 비공개 로컬 원본 바이트, public_sha256은 개인정보 제거 후 이 저장소에 올라간 바이트의 SHA256이다. raw 원본은 해시만 공개하며 public 파일은 누구나 직접 해시를 검증할 수 있다.
- 계정·호스트·개인 경로·이메일·토큰은 대체 표기로 제거했다. 원본 RTL/TB 소스는 변경하지 않았다.
- CH12 [XCRG dashboard](runs/ch12/report/functionalCoverageReport/dashboard.html), [교차 bin 상세](runs/ch12/report/functionalCoverageReport/grp0.html) 및 [실제 출력](runs/ch12/output.log).
- CH24 [기계 판독 실행 보고서](runs/ch24/report.json) 및 [음성 시험](runs/ch24/negative.log).
- [47개 시간·값 대조](timing_checks.json)는 선택한 공개 VCD 4개, SVA 로그, 커버리지 로그를 도식 계약과 비교한다. `python3 scripts/check_timing_evidence.py`로 재검사할 수 있다.
- [144개 화면 측정](visual/measurements.json) · [66개 구버전 실제 이동](visual/redirects.json). 도식·모바일 전수 검토 이미지는 `visual/diagrams-part1.webp`~`part6.webp`, `visual/mobile-part1.webp`~`part6.webp`에 있다.

## 12개 부정 시험 개별 종료 코드

| 장 | 시험 | 실제 종료 코드 | 검출 | 로그 |
|---:|---|---:|---|---|
| 10 | fault | 1 | PASS_NEG: `DETECTED_INJECTED_FAULT` | [전체](probes/ch10_fault.txt) |
| 10 | timeout | 1 | PASS_NEG: `DETECTED_APPLY_TIMEOUT` | [전체](probes/ch10_timeout.txt) |
| 11 | sva | 0 | PASS_NEG: `DETECTED_SVA_PENDING t=55` | [전체](probes/ch11_sva.txt) |
| 17 | NO_VIF | 0 | PASS_NEG: `[NOVIF]` | [전체](probes/ch17_NO_VIF.txt) |
| 18 | INVALID_DUTY | 0 | PASS_NEG: `[INVALID_DUTY]` | [전체](probes/ch18_INVALID_DUTY.txt) |
| 19 | CORRUPT_SAMPLE | 0 | PASS_NEG: `[SB_PWM]` | [전체](probes/ch19_CORRUPT_SAMPLE.txt) |
| 20 | NO_OVERRIDE | 0 | PASS_NEG: `[FACTORY]` | [전체](probes/ch20_NO_OVERRIDE.txt) |
| 20 | NO_CFG | 0 | PASS_NEG: `[NO_CFG]` | [전체](probes/ch20_NO_CFG.txt) |
| 20 | EARLY_DROP | 0 | PASS_NEG: `[COUNTS]` | [전체](probes/ch20_EARLY_DROP.txt) |
| 21 | NO_PREDICT | 0 | PASS_NEG: `[PREDICT_WRITE]` | [전체](probes/ch21_NO_PREDICT.txt) |
| 22 | CORRUPT_IRQ | 0 | PASS_NEG: `[IRQ_MISMATCH]` | [전체](probes/ch22_CORRUPT_IRQ.txt) |
| 24 | fault | 1 | PASS_NEG: `DETECTED_INJECTED_FAULT case=9` | [전체](probes/ch24_fault.txt) |

## CH01

- 명령: `bash -x scripts/run_chapter.sh 01`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:13.632299+00:00; 종료 코드: 0; 상태: EXECUTED_OBSERVATION.
- [실행 명령과 전체 출력](runs/ch01/runner.txt).
- 공개 로그: [output.log](runs/ch01/output.log).

```text
t=10 ns rx=00 rv=0 tr=0 | tx=00 tv=0 rr=0
t=20 ns rx=41 rv=1 tr=1 | tx=41 tv=1 rr=1
t=30 ns rx=5a rv=1 tr=0 | tx=5a tv=1 rr=0
t=40 ns rx=00 rv=0 tr=1 | tx=00 tv=0 rr=1
=== CH01 END: OBSERVATION ONLY ===
```

## CH02

- 명령: `bash -x scripts/run_chapter.sh 02`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:13.701801+00:00; 종료 코드: 0; 상태: EXECUTED_OBSERVATION.
- [실행 명령과 전체 출력](runs/ch02/runner.txt).
- 공개 로그: [output.log](runs/ch02/output.log).

```text
POS t=36 ns rst=1 apply=1 pending=1 period=8 duty=0 en=0 pwm=0
POS t=96 ns rst=1 apply=0 pending=0 period=8 duty=3 en=1 pwm=1
POS t=126 ns rst=1 apply=0 pending=0 period=8 duty=3 en=1 pwm=0
POS t=176 ns rst=1 apply=0 pending=0 period=8 duty=3 en=1 pwm=1
EVENT t=191 ns resetn=0 active_duty=3 pwm=0
POS t=196 ns rst=0 apply=0 pending=0 period=8 duty=0 en=0 pwm=0
=== CH02 END: OBSERVATION ONLY ===
```

## CH03

- 명령: `bash -x scripts/run_chapter.sh 03`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:13.769880+00:00; 종료 코드: 0; 상태: EXECUTED_OBSERVATION.
- [실행 명령과 전체 출력](runs/ch03/runner.txt).
- 공개 로그: [output.log](runs/ch03/output.log).

```text
OBSERVED duty=0 HIGH=0/8
OBSERVED duty=2 HIGH=2/8
OBSERVED duty=4 HIGH=4/8
OBSERVED duty=6 HIGH=6/8
OBSERVED duty=8 HIGH=8/8
=== CH03 END: OBSERVATION ONLY ===
```

## CH04

- 명령: `bash -x scripts/run_chapter.sh 04`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:13.838528+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch04/runner.txt).
- 공개 로그: [output.log](runs/ch04/output.log).

```text
PASS checks=11 errors=0
```

## CH05

- 명령: `bash -x scripts/run_chapter.sh 05`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:13.906812+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch05/runner.txt).
- 공개 로그: [output.log](runs/ch05/output.log).

```text
PASS checks=6 failures=0
```

## CH06

- 명령: `bash -x scripts/run_chapter.sh 06`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:13.975973+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch06/runner.txt).
- 공개 로그: [output.log](runs/ch06/output.log).

```text
PASS checks=11 failures=0 queue=0
```

## CH07

- 명령: `bash -x scripts/run_chapter.sh 07`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:14.049392+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch07/runner.txt).
- 공개 로그: [output.log](runs/ch07/output.log), [build.log](runs/ch07/build.log), [tool_version.txt](runs/ch07/tool_version.txt).

```text
PASS A_ACCEPT: data=41 valid=1 ready=1
PASS Z_STALL: data=5a valid=1 ready=0
PASS Z_ACCEPT: data=5a valid=1 ready=1
PASS IDLE: data=5a valid=0 ready=1
CH07 PASS: 4 cases checked
```

## CH08

- 명령: `bash -x scripts/run_chapter.sh 08`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:14.269755+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch08/runner.txt).
- 공개 로그: [output.log](runs/ch08/output.log), [build.log](runs/ch08/build.log), [tool_version.txt](runs/ch08/tool_version.txt).

```text
PASS DIRECT_A data=41 valid=1 ready=1
PASS RANDOM_IDLE data=2d valid=0 ready=1
PASS RANDOM_STALL data=72 valid=1 ready=0
PASS POLYMORPHIC_STALL data=72 valid=1 ready=0
CH08 PASS: 4 cases checked
```

## CH09

- 명령: `bash -x scripts/run_chapter.sh 09`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:14.438950+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch09/runner.txt).
- 공개 로그: [output.log](runs/ch09/output.log).

```text
RESET_GATE PASS t=581
PASS CH09 score_cycles=72 scenarios=6
```

## CH10

- 명령: `bash -x scripts/run_chapter.sh 10`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:14.475090+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch10/runner.txt).
- 공개 로그: [normal.log](runs/ch10/normal.log), [fault_injection.log](runs/ch10/fault_injection.log), [apply_timeout.log](runs/ch10/apply_timeout.log).

```text
PASS CH10 requests=3 checks=48
FATAL: <REPO>/tb/ch10/tb_pwm_corner_reset_timeout.sv:65: DETECTED_INJECTED_FAULT dut=1 measured=0
FATAL: <REPO>/tb/ch10/tb_pwm_corner_reset_timeout.sv:121: DETECTED_APPLY_TIMEOUT duty=8 deadline=10clks
```

## CH11

- 명령: `bash -x scripts/run_chapter.sh 11`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:14.544450+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch11/runner.txt).
- 공개 로그: [ch11.log](runs/ch11/ch11.log), [ch11_negative.log](runs/ch11/ch11_negative.log).

```text
PASS CH11 SVA checks=4
Fatal: DETECTED_SVA_PENDING t=55
```

## CH12

- 명령: `bash -x scripts/run_chapter.sh 12`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:24.495950+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch12/runner.txt).
- 공개 로그: [output.log](runs/ch12/output.log), [xcrg.log](runs/ch12/xcrg.log), [dashboard.html](runs/ch12/report/functionalCoverageReport/dashboard.html), [groups.html](runs/ch12/report/functionalCoverageReport/groups.html), [grp0.html](runs/ch12/report/functionalCoverageReport/grp0.html).

```text
PASS CH12 cases=12 coverage=100.00%
```

## CH13

- 명령: `bash -x scripts/run_chapter.sh 13`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:31.994203+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch13/runner.txt).
- 공개 로그: [simulation.log](runs/ch13/simulation.log).

```text
PASS CH13 accepted=3 checks=14
```

## CH14

- 명령: `bash -x scripts/run_chapter.sh 14`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:32.067747+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch14/runner.txt).
- 공개 로그: [simulation.log](runs/ch14/simulation.log).

```text
T1_TX_FIFO_PASS accepted=18 received=18
T2_RX_BACKPRESSURE_PASS checked=16
T3_RX_OVERRUN_PASS kept=17 dropped=1
T4_RESET_PASS
PASS CH14 tx=18 rx=16+17 overrun=1 reset=1
```

## CH15

- 명령: `bash -x scripts/run_chapter.sh 15`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:32.190334+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch15/runner.txt).
- 공개 로그: [simulation.log](runs/ch15/simulation.log).

```text
T1_AW_BEFORE_W_PASS
T2_W_BEFORE_AW_WSTRB_PASS
T3_CONTROL_RO_PASS
T4_ZERO_RO_ALIAS_PASS
T5_RESET_PENDING_PASS
PASS CH15 commits=7 checks=18
```

## CH16

- 명령: `bash -x scripts/run_chapter.sh 16`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:32.263001+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch16/runner.txt).
- 공개 로그: [simulation.log](runs/ch16/simulation.log).

```text
PASS CH16 cycles=21 basic_valid=12 pipe_valid=10
```

## CH17

- 명령: `bash -x scripts/run_chapter.sh 17`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:32.337016+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch17/runner.txt).
- 공개 로그: [normal.log](runs/ch17/normal.log), [negative.log](runs/ch17/negative.log), [elaborate.log](runs/ch17/elaborate.log).

```text
UVM_INFO <REPO>/tb/ch17/tb_pwm_uvm.sv(116) @ 180000: uvm_test_top.env [RESULT] PASS CH17 checks=8
UVM_FATAL <REPO>/tb/ch17/tb_pwm_uvm.sv(34) @ 0: uvm_test_top.env [NOVIF] pwm_if was not provided
```

## CH18

- 명령: `bash -x scripts/run_chapter.sh 18`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:19:53.113197+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch18/runner.txt).
- 공개 로그: [normal.log](runs/ch18/normal.log), [negative.log](runs/ch18/negative.log), [elaborate.log](runs/ch18/elaborate.log).

```text
UVM_INFO <REPO>/tb/ch18/tb_pwm_sequence_driver.sv(222) @ 500000: uvm_test_top [RESULT] PASS CH18 checks=3 samples=24
UVM_FATAL <REPO>/tb/ch18/tb_pwm_sequence_driver.sv(89) @ 180000: uvm_test_top.env.drv [INVALID_DUTY] duty=9 completed=1
```

## CH19

- 명령: `bash -x scripts/run_chapter.sh 19`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:20:13.496601+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch19/runner.txt).
- 공개 로그: [normal.log](runs/ch19/normal.log), [negative.log](runs/ch19/negative.log), [elaborate.log](runs/ch19/elaborate.log).

```text
UVM_INFO <REPO>/tb/ch19/tb_pwm_monitor_agent_scoreboard.sv(324) @ 340000: uvm_test_top [RESULT] PASS CH19 requests=3 applied=3 samples=24
UVM_FATAL <REPO>/tb/ch19/tb_pwm_monitor_agent_scoreboard.sv(237) @ 126000: uvm_test_top.env.sb [SB_PWM] t=126 phase=2 expected=0 got=1
```

## CH20

- 명령: `bash -x scripts/run_chapter.sh 20`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:20:33.527580+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch20/runner.txt).
- 공개 로그: [normal.log](runs/ch20/normal.log), [alt.log](runs/ch20/alt.log), [NO_OVERRIDE.log](runs/ch20/NO_OVERRIDE.log), [NO_CFG.log](runs/ch20/NO_CFG.log), [EARLY_DROP.log](runs/ch20/EARLY_DROP.log).

```text
UVM_INFO <REPO>/tb/ch20/tb_pwm_factory_config_objection.sv(410) @ 340000: uvm_test_top [RESULT] PASS CH20 factory=traced plan=2,6,0 applied=3 samples=24
UVM_INFO <REPO>/tb/ch20/tb_pwm_factory_config_objection.sv(410) @ 340000: uvm_test_top [RESULT] PASS CH20 factory=traced plan=1,8,3 applied=3 samples=24
UVM_FATAL <REPO>/tb/ch20/tb_pwm_factory_config_objection.sv(374) @ 30000: uvm_test_top [FACTORY] Driver type override was ignored
UVM_FATAL <REPO>/tb/ch20/tb_pwm_factory_config_objection.sv(90) @ 0: uvm_test_top.env.ag.drv [NO_CFG] Driver config not found
UVM_FATAL <REPO>/tb/ch20/tb_pwm_factory_config_objection.sv(400) @ 270000: uvm_test_top [COUNTS] Incomplete verification samples=17
```

## CH21

- 명령: `bash -x scripts/run_chapter.sh 21`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:21:03.588742+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch21/runner.txt).
- 공개 로그: [normal.log](runs/ch21/normal.log), [negative.log](runs/ch21/negative.log), [elaborate.log](runs/ch21/elaborate.log).

```text
UVM_INFO <REPO>/tb/ch21/tb_axi_uvm_ral.sv(386) @ 450000: uvm_test_top [RESULT] PASS CH21 RAL reads=7 writes=3
UVM_FATAL <REPO>/tb/ch21/tb_axi_uvm_ral.sv(336) @ 170000: uvm_test_top [PREDICT_WRITE] addr=00000010 expected=11223344
```

## CH22

- 명령: `bash -x scripts/run_chapter.sh 22`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:21:24.327353+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch22/runner.txt).
- 공개 로그: [normal.log](runs/ch22/normal.log), [negative.log](runs/ch22/negative.log), [elaborate.log](runs/ch22/elaborate.log).

```text
UVM_INFO <REPO>/tb/ch22/tb_axi_multiagent_irq.sv(674) @ 1280000: uvm_test_top [RESULT] PASS CH22 AXI_W=6 AXI_R=13 IRQ=4 RESET=2 COLLISION=1 ZERO=1
UVM_FATAL <REPO>/tb/ch22/tb_axi_multiagent_irq.sv(447) @ 716000: uvm_test_top.env.sb [IRQ_MISMATCH] status=10 expected=11 collisions=1
```

## CH23

- 명령: `bash -x scripts/run_chapter.sh 23`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:21:45.515464+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch23/runner.txt).
- 공개 로그: [simulation.log](runs/ch23/simulation.log).

```text
REJECT len=0
REJECT len=3
REJECT len=65
REJECT len=1
PASS CH23 cases=8 rejected=4
```

## CH24

- 명령: `bash -x scripts/run_chapter.sh 24`, cwd: 저장소 루트.
- 실행 UTC: 2026-11-25T22:21:45.641189+00:00; 종료 코드: 0; 상태: PASS.
- [실행 명령과 전체 출력](runs/ch24/runner.txt).
- 공개 로그: [compile.log](runs/ch24/compile.log), [seed_1.log](runs/ch24/seed_1.log), [seed_7.log](runs/ch24/seed_7.log), [seed_42.log](runs/ch24/seed_42.log), [negative.log](runs/ch24/negative.log), [report.json](runs/ch24/report.json).

```text
COVERAGE seed=1 idle=6 stall=12 accept=9 ready_idle=5
PASS CH24 seed=1 checks=32 accepted=9
COVERAGE seed=7 idle=9 stall=7 accept=11 ready_idle=5
PASS CH24 seed=7 checks=32 accepted=11
COVERAGE seed=42 idle=12 stall=5 accept=9 ready_idle=6
PASS CH24 seed=42 checks=32 accepted=9
FATAL: <REPO>/tb/ch24/tb_uart_regression.sv:56: DETECTED_INJECTED_FAULT case=9
```
