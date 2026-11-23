> 이전 기록: 이 문서는 `amd_soc_rtl/system_verilog_uvm_tb`에서 작성한 당시의 검증 기록을 옮긴 것입니다. 독립 저장소 이관 후의 새 검증 결과는 `docs/MIGRATION_v01.md`를 참조하세요. 실제 시뮬레이션 미실행 상태는 그대로 유지됩니다.

# 제06장 검증 기록 · v01

- **원본 DUT:** `part03/common/rtl/uart_echo_controller.v`
- **원본 Blob SHA:** `28160c34522e47fbd961466651598da063bc74ae`
- **중앙 규칙 SHA:** AGENTS `58b59ecd9bcd2c23af0f397af2bd4de5d575b540`, STANDARD `f78630d1de218733569b063ae5428ba9c0589f7f`
- **대상:** `tb/ch06/uart_expect_pkg.sv`, `tb/ch06/tb_uart_arrays_queues.sv`, `scripts/run_ch06.sh`, `ch06_arrays_queues_packages_v01.html`

| 항목 | 상태 | 근거 |
|---|---|---|
| 원본 6개 포트와 TB 연결 | PASS (정적) | 실제 원본 선언과 인스턴스 연결 대조 |
| 원본 RTL·기존 교재 보존 | PASS (범위 확인) | 독립 교육과정 내부만 새 파일 작성 |
| packed/unpacked 인덱스 및 큐 순서 | PASS (정적) | 41·42·43·44, `[3-i]`, 수락 시에만 `pop_front()` |
| 패키지 정의 및 컴파일 순서 | PASS (정적) | `uart_expect_pkg.sv` 먼저 지정 |
| HTML 절·내비게이션·코드/도식 신호명 | PASS (정적) | 8개 절, 실제 DUT 6포트와 용어 대조 |
| 개인정보·토큰·로컬 경로 노출 | PASS (정적) | 공개 자료에 개인 식별정보·실제 절대경로 없음 |
| RTL 컴파일/시뮬레이션 | NOT_RUN | 현재 실행 환경에 `iverilog`/`vvp`/`verilator` 실행 파일 없음 |
| 실제 VCD·출력 로그 | NOT_RUN | 실행 미실시, HTML의 출력은 예상값으로 표시 |
| 실제 브라우저 모바일·복사 버튼 | NOT_RUN | 정적 경로·속성만 검사, 실브라우저 미검증 |

**예상 결과(실측 아님):** 4개 바이트 A/B/C/D를 큐에 넣고, ready=0인 B를 제거하지 않으며, 수락 시에만 pop_front. 최종 checks=11, failures=0, queue=0 예상.

**재검증:** Ubuntu에서 `bash scripts/run_ch06.sh` 실행 후 컴파일러 버전·실제 output.log·VCD를 확보한다. 지원하지 않는 큐 문법이 있으면 원본 DUT를 수정하지 말고 검증 도구 호환성을 확인한다.
