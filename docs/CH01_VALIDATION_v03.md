# 제01장 v03 검증 기록

- DUT 원본/스냅샷 Blob: 28160c34522e47fbd961466651598da063bc74ae; TB Blob: cbb38e1db12bf1e7092c60572adf9051b9ac07ef. 원본 및 TB 변경 없음.
- 정적 확인: 전체 원본 RTL 및 TB 문자열 HTML 일치, 외부 원본 프로젝트 링크 및 SHA 본문 제거, 독립 실습 폴더·파일명·직접 실행 절차, 도식 3개 인라인 포함.
- 수정 연결도: 실제 DUT 1개, 6개 포트, 3개 assign 문, 입력/출력 화살표 방향 대조. 수정 SVG Blob 973eec348dfea94b2c502ccf75f2d160a0f51428는 로컬 Chromium으로 렌더링한 파일과 일치.
- 수정 연결도 단독 Chromium 렌더링: 텍스트 겹침 0건, 모든 텍스트 viewBox 내부, 3개 assign 텍스트 DUT 내부. 실제 스크린샷 확인. 전체 페이지/모바일/편집기 왕복/Pages 실접속: NOT_RUN.
- RTL_SIM: NOT_RUN (로컬 xvlog/xelab/xsim/iverilog/verilator 명령 없음).
- 원본 프로젝트 링크·SHA는 학생 본문에서 제거하고 출처 추적은 이 검증 기록과 source_manifest.md에만 유지.
