# 제01장 v02 검증 기록

- 원본 DUT Blob SHA: 28160c34522e47fbd961466651598da063bc74ae (amd_soc_rtl 원본과 동일).
- TB Blob SHA: cbb38e1db12bf1e7092c60572adf9051b9ac07ef; 기존 TB 및 실행 스크립트 변경 없음.
- 정적 확인: HTML에 원본 DUT/TB 전체 문자열 포함, 8개 절, 24장 목록, 시간 배분 제거, 세 연속 대입과 예상 파형의 논리값 수동 대조.
- SVG: source-based 도식 및 예상 파형, 편집용 JSON은 정본 예제 구조를 참고. 실제 편집기 왕복/브라우저 렌더링: NOT_RUN.
- RTL_SIM: NOT_RUN (XSIM/Icarus/Verilator 명령 미설치). 예상 출력은 실측 로그가 아님.
- GitHub Pages 실접속: NOT_RUN.
- 기존 v01 URL은 이전 장 링크를 위해 최신 v02 안내용으로만 유지. 기존 본문은 Git 이력에 보존.
