# 제12장 v02 검증 기록

## 원본 및 변경 범위
- amd_soc_p2 04.2장 02·06절, p2_04_2_rtl_v02.html (f42a821b9a35572d0940c24d6781bafb8287f21e). 현행 legacy/part02_1/ch04/rtl/pwm_core.v와 reference_rtl/pwm_core.v Blob e813f3fb107bd327054d11e0b397817b8e7bd813 동일. 원본 수정 없음.
- 기존 3×2×2 교차 bin, 12개 사례, HIGH 합계 비교 유지. 각 표본의 기대 위상 레벨 및 활성 상태 검사 추가. 정상 확인된 실제 활성 포트로 cov.sample() 실행. visited[11:0]으로 조합 누락 및 중복 사례에 의한 허위 완료 방지.
- middle은 1~7의 단일 bin, 대표값 4만 시험. 12개 분류와 합법 값 36개 조합 전수 시험 구별.
- XSIM 우선 독립 실행, 새 실행 폴더, 정상 완료 문자열 검사, xcrg 지원 시 HTML 보고서 생성, 조건부 VCD. TB 1526432b9737b11b34d44ac5cb46dc620839ee81, 스크립트 8947ee6d80356d73bc683d1767b2ebcafcf12a26.
- AMD UG900 2024.1 Test Bench Feature 및 2022.2 Functional Coverage Report Generator에서 covergroup, bins, cross, 사용자 sample 및 보고서 옵션 확인. 실제 설치 버전 실행 미검증.
  https://docs.amd.com/r/2024.1-English/ug900-vivado-logic-simulation/Test-Bench-Feature
  https://docs.amd.com/r/2022.2-English/ug900-vivado-logic-simulation/Functional-Coverage-Report-Generator

## 독립 계산 (실측 아님)
- 초기 리셋 해제 30ns, 첫 요청 40ns·수락 45ns·적용 105ns·관찰 110ns. 120~190ns에 위상 1,2,3,4,5,6,7,0 관찰. 다음 사례마다 160ns 증가. 마지막 1950ns 종료 예상.
| duty | en | pol | 기대 표본 | HIGH |
|---:|---:|---:|---|---:|
| 0 | 0 | 0 | 00000000 | 0 |
| 0 | 0 | 1 | 00000000 | 0 |
| 0 | 1 | 0 | 00000000 | 0 |
| 0 | 1 | 1 | 11111111 | 8 |
| 4 | 0 | 0 | 00000000 | 0 |
| 4 | 0 | 1 | 00000000 | 0 |
| 4 | 1 | 0 | 11100001 | 4 |
| 4 | 1 | 1 | 00011110 | 4 |
| 8 | 0 | 0 | 00000000 | 0 |
| 8 | 0 | 1 | 00000000 | 0 |
| 8 | 1 | 0 | 11111111 | 8 |
| 8 | 1 | 1 | 00000000 | 0 |
- 12개 사례·96개 표본, visited FFF 예상. 실제 get_coverage() 미측정. 위상 이동 반례(11100001→00011110)는 합계 4가 같지만 표본 비교에서 불일치한다. 공통 시간 기준 오류와 표본 사이 글리치 등은 놓칠 수 있다. 실제 오류 주입 미실행.
- SVG 단독 Chromium 렌더 및 스크린샷 확인: 텍스트 29개, 겹침 0, viewBox 초과 0. Blob 5985b98139f9427e8458e32bdd78ca0f03fbf36d, HTML 인라인 동일. 매트릭스이므로 플로우 편집기 JSON 미제작.
- 원격 HTML 9b77be8ab0361a5a5f9b43cf58378accb8340c23: RTL/TB/스크립트 원문, 8절, 24장 탐색, INDEX, 중복 ID, 예상/실측 구분 정적 확인.

## 판정
- 원본 대조, 독립 계산, SVG 단독 렌더 및 원격 정적 검사: PASS (해당 범위).
- 실제 RTL_SIM(XSIM), 커버리지 엔진, xcrg 보고서 생성, 변이 시험: NOT_RUN — 로컬 실행 도구 부재.
- 전체 HTML·모바일·Pages 실접속: NOT_RUN.
