> 이전 기록: 이 문서는 `amd_soc_rtl/system_verilog_uvm_tb`에서 작성한 당시의 검증 기록을 옮긴 것입니다. 독립 저장소 이관 후의 새 검증 결과는 `docs/MIGRATION_v01.md`를 참조하세요. 실제 시뮬레이션 미실행 상태는 그대로 유지됩니다.

# 제05장 검증 기록 · v01

- **교육과정:** `system_verilog_uvm_tb` / 제2부 제05장 (60분 + 60분)
- **기준 규칙:** `Yuul-Jung/rule_md` AGENTS.md, HTML STANDARD.md, 코드·스타일·도식 규칙 확인
- **원본 RTL:** `part03/common/rtl/uart_echo_controller.v`
- **원본 Blob SHA:** `28160c34522e47fbd961466651598da063bc74ae`
- **원본 수정:** 없음
- **신규 파일:** `ch05_verification_types_v01.html`, `tb/ch05/tb_uart_types.sv`, `scripts/run_ch05.sh`
- **정적 검증:** PASS — 실제 6포트 이름과 폭 일치, 조합 시간 계약, 9개 HTML 절, SVG 도식 신호, 코드와 링크, 예시와 실측 구분
- **RTL 컴파일/실행:** NOT_RUN — 실행 환경에서 `iverilog`, `vvp`, `verilator` 미설치
- **VCD 파형 확인:** NOT_RUN
- **실브라우저·모바일·코드 복사 실행:** NOT_RUN (정적 구조만 확인)
- **예상 결과:** 4개 사례의 MATCH, logic=x5, bit=05, PASS checks=6 failures=0 (실측 아님)
- **보안:** 공개 산출물에 사용자 비밀, 토큰, 실제 개인 경로를 포함하지 않음
- **추후 실행:** Ubuntu에서 `bash scripts/run_ch05.sh` 후 실제 로그·VCD 확보, 도구 버전과 함께 검증 기록 갱신
