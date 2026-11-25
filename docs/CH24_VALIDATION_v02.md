# 제24장 검증 기록 v02

- 원본 DUT Git Blob SHA: 28160c34522e47fbd961466651598da063bc74ae (원격 파일 조회 확인, 수정하지 않음).
- 부정 시험: 9번째 관찰 데이터 하위 비트 반전 → 공통 비교기 검출. 실제 DUT 출력이 정상일 때만 지정 마커 출력.
- Python: 실제 DUT/TB SHA 계산, 원본 불일치 FAIL, 시드 1~2147483647, 독립 커버리지·accepted 교차 확인, 실행별 폴더, 타임아웃/실행 오류 구분.
- CI: 읽기 권한, 시간 제한, 숨김 로그 보존 설정. UART 단일 DUT 검증에 한정.
- 정적 검증: HTML 7개 절 ID, 원본과 수정 코드 삽입 내용 일치, 최신 INDEX 목차 동기화, 원본 포트 계약.
- 독립 JS 32비트 계산 결과 (idle/stall/accept/ready_idle): 1: 6/12/9/5, 7: 9/7/11/5, 42: 12/5/9/6. 각 합 32.
- RTL_SIM=NOT_RUN; PYTHON_EXEC=NOT_RUN; CI_RUN=NOT_RUN; BROWSER_VISUAL=NOT_RUN. 실제 실행 없이 PASS 주장 금지.
