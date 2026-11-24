# 제02장 v02 적대적 검증 기록

## 설계 매칭
- amd_soc_npu 제2부 04.2장 02절·06절, `part02/p2_04_2_rtl_v02.html` (ea29ad1cf7885f546258b588ae8b600fb3516888).
- 원본 `part02/legacy/part02_1/ch04/rtl/pwm_core.v`와 검증 스냅샷 Blob e813f3fb107bd327054d11e0b397817b8e7bd813 일치. 원본 수정 없음.
- DUT 7입력·6출력, 외부 사용자 RTL 의존 없음. 전체 소스/전체 TB 본문 포함.

## 발견 및 조치
- 기존 TB의 %0t와 고정 ns 접미사는 시간 정밀도와 표시 단위 혼동 가능: %0d $time으로 수정(모듈 단위 1ns).
- Icarus VCD 기록을 VCD 매크로로 분리, 실행 스크립트에 -DVCD 추가. XSIM은 매크로 없이 컴파일하고 GUI 파형 사용. AMD UG900 XSIM 실행 옵션 및 VCD 문서 참고.
- 기존 TB 자극·DUT 포트·비교 시점 변경 없음. TB Blob 56edb731254bedf17a293c3f1f2f557b43209ba6; 실행 스크립트 Blob 953f7ed823712eee2e916ef30f61768f7c05d915.
- 독립 Python 이벤트 모델로 26/36/96/126/176/191/196ns의 8개 관측/내부 값 대조: 7개 시점 일치. 실제 RTL 시뮬레이션 아님. 0~5ns 미정 레지스터와 190ns 조합 출력 차단/195ns 순차 리셋 구분.
- 구조도 초안 Chromium getBBox에서 텍스트 겹침 6건 발견, 글자 크기·줄간격/연결 경로 조정 후 0건. 최종 구조도와 예상 파형 각각 실제 Chromium 렌더링 및 getBBox 검사(겹침 0, viewBox 초과 0). 로컬 파일과 원격 Blob 동일: bb3a0f4d8dcf183e7123c3ad58f510e7c1ba17ee, 2781054810e4f1b04fe4ebc2cc328ec590fc3c41. 도식은 독립 SVG 원본 및 HTML 인라인 포함. 편집기 JSON 왕복 미수행.
- 원격 HTML/RTL/TB/스크립트/SVG 및 INDEX/course.json 재조회: 내용 일치, 8절, 시간 배분 제거, 비공개 설계 URL 없이 장·절·파일명 제공. 기존 v01 URL은 v02로 연결.

## 실행 상태
- Python 예상 상태 계산: PASS (독립 계산 모델에 한함).
- 두 SVG 단독 렌더링: PASS.
- RTL_SIM(XSIM/Icarus): NOT_RUN — 로컬 환경에 해당 명령 없음.
- 전체 HTML 브라우저/모바일/Pages 실접속 및 편집기 JSON: NOT_RUN.
- 실제 시뮬레이션·합성·보드 결과를 확정하지 않는다.
