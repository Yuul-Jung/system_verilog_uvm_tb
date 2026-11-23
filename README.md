# RTL Testbench · SystemVerilog · UVM 검증 학습안내서

- **전체 편성:** 독립 6부, 총 24장/48시간, 한 장은 60분 × 2회로 진행
- **발행:** [INDEX](index.html) / [제01장](ch01_testbench_basics_v01.html) / [제02장](ch02_clock_reset_events_v01.html) / [제03장](ch03_reusable_stimulus_v02.html) / [제04장](ch04_pass_fail_automation_v02.html) / [제05장](ch05_verification_types_v02.html) / [제06장](ch06_arrays_queues_packages_v02.html) / [제07장](ch07_interface_modport_clocking_v01.html) / [전체 편성](CURRICULUM.md)
- **원본 RTL:** 제01장은 `part03/common/rtl/uart_echo_controller.v`, 제02~03장은 `part02_1/ch04/rtl/pwm_core.v`를 읽기 전용 DUT로 사용
- **목표:** 문법 → Testbench → Self-checking → SVA/Coverage → UVM → Regression/CI
- **상태:** 제01~07장 배포용 HTML·TB·실행 스크립트 발행. 제07장은 정적 분석 완료, **RTL_SIM=NOT_RUN** (실행 환경에 Verilator 없음).

## 규칙
- 정본 [rule_md](https://github.com/Yuul-Jung/rule_md) / [HTML STANDARD](https://github.com/Yuul-Jung/rule_md/blob/d1b8278d41fca8f5e3960736f3ac9d377e462fda/web/education-html/STANDARD.md)
- 기존 `amd_soc_rtl`의 `AGENTS.md`와 [공통 코드 스타일](https://github.com/Yuul-Jung/rule_md/blob/d1b8278d41fca8f5e3960736f3ac9d377e462fda/common/code-style-rules.md) 적용
- 원본 수정 금지, 공개 보안 점검, 실행 기록 기반으로만 PASS 표기, 장별 `_vNN.html` 사용

## 독립 저장소 설치 (Ubuntu)

GitHub 원격 저장소 이름은 현재 `system_velirog_uvm_tb`입니다(원래 의도한 `verilog`와 철자가 다름). 로컬 디렉터리는 정상 철자 `system_verilog_uvm_tb`로 복제할 수 있습니다.

```bash
# 별도 GitHub 저장소를 원하는 로컬 폴더 이름으로 복제한다.
git clone https://github.com/Yuul-Jung/system_velirog_uvm_tb.git system_verilog_uvm_tb
cd system_verilog_uvm_tb
```

이 과정은 **독립 저장소 루트**를 기준으로 동작합니다. `reference_rtl/`은 `amd_soc_rtl`에서 읽기 전용으로 복사한 **원본 동일 스냅샷**입니다. 다른 버전의 DUT 검증이 필요하면 `DUT_PATH`로 원본 파일을 직접 지정합니다.

## 제01~07장 실행 (Ubuntu)
```bash
# 위 git clone 작업으로 이 폴더에 진입한 상태에서 실행
# pwd로 현재 경로를 확인한다
sudo apt update
sudo apt install -y iverilog
bash scripts/run_ch01.sh
bash scripts/run_ch02.sh
bash scripts/run_ch03.sh
bash scripts/run_ch04.sh
bash scripts/run_ch05.sh
bash scripts/run_ch06.sh
# 제07장은 clocking block 실습으로 Verilator를 사용함
verilator --version
bash scripts/run_ch07.sh
```

별도 복제 저장소에서도 실행할 수 있습니다.
```bash
DUT_PATH=/실제/RTL/경로/uart_echo_controller.v bash scripts/run_ch01.sh
DUT_PATH=/실제/RTL/경로/pwm_core.v bash scripts/run_ch03.sh
```

`.build/`는 로컬 생성물이며 GitHub에 올리지 않습니다. 온라인 학습안내서는 `index.html`로 시작합니다.

## HTML 레이아웃·내비게이션 보정
- 제03~06장 `_v02.html`: 누락된 `<main class="content" id="main-content">` 영역을 복구하고, 좌측 세부 절 탐색이 `main section[id]`를 정상 식별하도록 수정.
- INDEX와 `course.json`을 최신 발행 장에 맞춰 동기화. 디자인·기존 RTL·실습 코드 변경 없음.
- 실제 GitHub Pages HTTP 접속은 별도로 확인해야 하며, 저장소 파일 존재를 공개 사이트 정상 구동과 혼동하지 않는다.

## 좌측 목차 체계
`PART(부) → CHAPTER(장) → SECTION(절)`의 계층을 사용합니다. 현재 페이지의 PART는 상단에 한 번만 표시하고, 해당 PART의 CHAPTER 아래 현재 장 SECTION을 들여씁니다. 전체 6개 PART와 24장 편성은 INDEX에서 확인할 수 있습니다. 공통 스타일의 로컬 확장으로 `assets/site.js`와 `assets/site.css`에서 구현합니다.

### 제07장 시뮬레이터 안내
- 제01~06장 실행과 달리 제07장은 interface·modport·clocking block 지원이 필요한 SystemVerilog 실습이다.
- Verilator 버전에 따라 지원 차이가 있을 수 있다. `sudo apt install verilator g++ make` 후 `verilator --version`을 확인한다.
- `bash scripts/run_ch07.sh`는 도구·원본 파일을 확인하고 빌드·실행 로그를 `.build/ch07/`에 보관한다.
- 실제 컴파일·시뮬레이션 성공이 확인되기 전에는 PASS로 기록하지 않는다.

## 발행 위치

- **정본(배포·커밋 대상):** `Yuul-Jung/system_velirog_uvm_tb` 저장소 **최상위 루트**.
- **참고(과거 잘못 작성한 사본):** `Yuul-Jung/amd_soc_rtl/system_verilog_uvm_tb/`. 이 경로에 신규 커밋하지 않습니다.
- **원본 DUT:** `reference_rtl/`에는 원본과 동일한 2개 파일을 보관합니다. 복사본의 Git Blob SHA를 원본과 비교합니다.
- **예상 결과와 실제 실행 판정:** 실제 시뮬레이터 실행 증거가 없으면 `NOT_RUN`으로 표시합니다.
