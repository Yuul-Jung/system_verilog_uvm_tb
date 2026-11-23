> 이전 기록: 이 문서는 `amd_soc_rtl/system_verilog_uvm_tb`에서 작성한 당시의 검증 기록을 옮긴 것입니다. 독립 저장소 이관 후의 새 검증 결과는 `docs/MIGRATION_v01.md`를 참조하세요. 실제 시뮬레이션 미실행 상태는 그대로 유지됩니다.

# 제07장 · 인터페이스·타이밍 분리 검증 기록 v01

**과정:** `system_verilog_uvm_tb` · PART 02, CHAPTER 07 · 1교시(60분) + 2교시(60분)  
**원본 RTL:** `part03/common/rtl/uart_echo_controller.v` · Blob `28160c34522e47fbd961466651598da063bc74ae`  
**규칙:** `Yuul-Jung/rule_md` (`AGENTS.md`, `web/education-html/STANDARD.md`, `common/code-style-rules.md`, `common/flowchart-rules.md`) + 과정 `AGENTS.md`

| 점검 항목 | 판정 | 내용 |
|---|---|---|
| 중앙 규칙·프로젝트 규칙 확인 | 통과(문서) | 고정 HTML 디자인과 과정 전용 PART→CHAPTER→SECTION 메뉴 보존 |
| 원본 RTL·6개 포트 일치 | 통과(정적) | `rx_data_i`, `rx_valid_i`, `tx_ready_i`, `rx_ready_o`, `tx_data_o`, `tx_valid_o` 대조 |
| 래퍼와 모드포트 방향 일치 | 통과(정적) | `uart_echo_bind`의 포트 6개를 `uart_stream_if.DUT` 방향과 대조 |
| Clocking skew·시나리오 순서 | 통과(논리 검토) | `input #1step output #0`, 5/15/25/35/45ns 구동·샘플 순서 |
| Ready/Valid 정지 시 데이터 유지 | 통과(정적) | `Z_STALL` 후 `tx_ready_i`만 변경, `Z_ACCEPT` 이후 Valid 해제 |
| HTML 본문·실습 코드·도식 정합성 | 통과(정적) | `main` 구조와 11절, 원본 포트·TB 이름 대조 |
| INDEX·목차·이전/다음 연결 | 통과(정적) | COURSE 등록 7장, INDEX 발행 장만 연결 |
| 보안·개인정보 노출 | 통과(정적) | 예제와 본문 중 민감한 값·계정·토큰 없음 |
| SystemVerilog 컴파일 | NOT_RUN | 제작 환경에 Verilator/Icarus 설치 없음. 인터페이스 clocking 구문 지원 시뮬레이터 필요 |
| DUT RTL 시뮬레이션·자동 검사 | NOT_RUN | 실제 이진 프로그램·실행 로그 미생성 |
| VCD 파형과 GTKWave 확인 | NOT_RUN | 실행 후 생성되므로 아직 없음 |
| Chromium 브라우저 렌더링·모바일 클릭 | NOT_RUN | 실브라우저에서 실제 사이트 접근 불가 |
| GitHub Pages 실제 접속 | NOT_RUN | URL 접근 실패/검증 불가. GitHub에 파일 존재함과 별개 |

## 예상 결과(실행 로그 아님)
- t=5ns: `A` 구동 → t=15ns: `A_ACCEPT` (41, Valid 1, Ready 1).
- t=15ns: `Z` 구동, Ready 0 → t=25ns: `Z_STALL` (5A, 1, 0).
- t=25ns: Z·Valid 유지, Ready 1 → t=35ns: `Z_ACCEPT` (5A, 1, 1).
- t=35ns: Valid 0 → t=45ns: `IDLE` (5A, 0, 1).
- 모두 일치할 때 `CH07 PASS: 4 cases checked` 출력이 설계되어 있다. **실제 PASS가 확인된 것은 아니다.**

## 실제 검증용 절차
```bash
cd system_verilog_uvm_tb
verilator --version
bash scripts/run_ch07.sh
```
실행 가능한 Verilator 버전에서 컴파일·로그·VCD를 확인하고, 미지원으로 실패하면 오류 로그를 기록한 뒤 지원 버전을 사용한다. 시뮬레이션 미실행을 PASS로 표시하지 않는다.
