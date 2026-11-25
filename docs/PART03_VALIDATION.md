# 제3부(09~12장) 종합 검증

| 장 | 검증 축 | 발행 |
|---|---|---|
| 09 | 참조 모델·6개 공개 출력 사이클 비교 | ch09_reference_model_scoreboard_v03.html |
| 10 | 경계값·리셋·오류 주입·실패 판정 | ch10_corner_reset_timeout_v03.html |
| 11 | SVA 시간 계약·선행 조건 발생 확인 | ch11_temporal_assertions_v02.html |
| 12 | 기능 커버리지·교차 조합·표본 순서 | ch12_functional_coverage_v02.html |

## 적대적 검토 및 조치
- 4장 동일 PWM 원본(e813f3fb107bd327054d11e0b397817b8e7bd813), amd_soc_p2 04.2장 02·06절. 원본 유지. 독립 TB, 8클록 주기·10ns 클록 기준. AXI·보드·임의 주기 검증 아님.
- 09장 모델과 DUT의 공통 오류 가능성, 10장 의도적 오류와 별개 실패 구별, 11장 선행 조건 발생과 실제 assertion 평가 구별, 12장 HIGH 개수와 위상 순서 및 12개 분류와 36개 합법 값 조합 구별. 각 한계를 본문에 명시.
- 09~11장 최신 탐색 데이터로 동기화. 12장 샘플 사이 안정성 표현을 각 관찰 표본으로 제한. 기존 URL 호환 유지.
- 전체 RTL·TB 원문, 09장 모델 및 10~12장 스크립트 일치. 09장은 독립 직접 실행 명령 제공. 네 장 8절·24개 장 탐색·중복 ID 없음·정확한 설계 참조·XSIM 우선·예상 출력 구분 확인.
- 장별 독립 계산: 09장 72클록·6요청, 10장 48회 비교·두 부정 경로, 11장 4개 적용·다섯 선행 조건, 12장 12개 사례·96개 표본. 실제 실행 로그 아님.

| 검증 항목 | 상태 |
|---|---|
| 원본·포트·의존 파일 | PASS (정적 4/4) |
| 선수 관계·검증 범위·중복 | 정적 검토 완료 |
| 24장 탐색·INDEX | PASS (정적) |
| 장별 독립 계산 | PASS (계산 범위) |
| SVG 단독 렌더 | 장별 기록 및 12장 실제 렌더 확인 |
| RTL_SIM·오류 주입·SVA·커버리지 | NOT_RUN |
| 전체 페이지·모바일·Pages 실접속 | NOT_RUN |
| 편집기 JSON 왕복 | NOT_RUN |

최종 원격 HTML Blob:
- ch09_reference_model_scoreboard_v03.html: 919353ca378702c24e6776ac9272e3cbcd4f4bae
- ch10_corner_reset_timeout_v03.html: 73fd1f84325e30bb1e52e1e9f5b1231f786d10d8
- ch11_temporal_assertions_v02.html: df07a0c6d7f113b4c0fa3b3b27d0ac535df6b359
- ch12_functional_coverage_v02.html: 9b77be8ab0361a5a5f9b43cf58378accb8340c23

제3부 개정과 정적 종합 검증 완료. 실제 실행은 별도 미검증 항목. 다음은 제4부 UART 스트림 검증.
