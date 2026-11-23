> 이전 기록: 이 문서는 `amd_soc_rtl/system_verilog_uvm_tb`에서 작성한 당시의 검증 기록을 옮긴 것입니다. 독립 저장소 이관 후의 새 검증 결과는 `docs/MIGRATION_v01.md`를 참조하세요. 실제 시뮬레이션 미실행 상태는 그대로 유지됩니다.

# 제1장 제작·검증 기록 · v01

**대상:** `system_verilog_uvm_tb` · 제01장 Testbench 기초  
**정본:** `Yuul-Jung/rule_md` · HTML STANDARD / 코드 작성 표준  
**DUT 원본:** `part03/common/rtl/uart_echo_controller.v` · Blob `28160c34522e47fbd961466651598da063bc74ae`

| 검증 항목 | 판정 | 확인 근거 |
|---|---|---|
| 중앙 HTML·코드 규칙 열람 | 통과 | 정본 rule_md AGENTS/STANDARD/CODE 표준 확인 |
| 6부·24장 INDEX 편성 | 통과 | index 6부, CURRICULUM.md 24장 항목 확인 |
| 실제 발행된 장만 연결 | 통과 | 제01장 1개 링크, 제02~24장 404 방지 |
| RTL 원본 보존 | 통과 | 기존 DUT 파일 쓰기 없음; Blob SHA 기록 |
| 포트·코드·도식 일치 | 통과(정적) | DUT 6포트 이름과 TB·HTML 대조 |
| 색상·상단 이미지·탐색 구현 | 통과(정적) | 최신 공통 CSS/JS, 책장 이미지 고정 경로 |
| 키보드 Escape·코드 복사·모바일 구현 | 통과(정적) | 공통 JavaScript/CSS 기능 코드 확인 |
| HTML 상대 파일·중복 ID | 통과(정적) | 리소스 4개 경로, 두 HTML 중복 id 없음 |
| SystemVerilog 컴파일 | NOT_RUN | 제작 환경에 Icarus Verilog 실행기 없음 |
| DUT RTL 시뮬레이션 | NOT_RUN | 실제 vvp 로그 미생성 |
| VCD 파형 판독 | NOT_RUN | 실제 파형 미생성 |
| 시각·반응형 브라우저 실측 | NOT_RUN | 실브라우저 렌더링 확인 필요 |
| GitHub Pages 게시 상태 | NOT_RUN | 공개 Pages 설정·배포 확인 없음 |

### 기대 논리 (실행 결과 아님)
`tx_data_o`는 `rx_data_i`, `tx_valid_o`는 `rx_valid_i`, `rx_ready_o`는 `tx_ready_i`를 그대로 전달한다.  
시험 입력 4개 시점(10/20/30/40ns)의 출력 예시는 조합 논리식에 따른 **예상값**으로 표시하였다.

### 남은 검증
Ubuntu에서 `bash scripts/run_ch01.sh`를 실제로 실행하고 출력 로그/VCD를 원본 SHA 및 도구 버전과 묶어서 저장한 뒤, PASS/FAIL을 판정한다. 접근성·코드 복사·모바일 탐색은 실제 브라우저에서 검증한다. 미실행 시험을 PASS로 표기하지 않는다.
