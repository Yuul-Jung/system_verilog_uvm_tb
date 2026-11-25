# 제08장 v02 검증 기록

## 원본 매칭
- amd_soc_npu 제1장 UART 계산기 03절 서브젝트 1-1 UART 에코, p01_uart_calc_v01.html (f1089413362a271717b6a4b6a2e95deb569334f2).
- 현행 common/rtl/uart_echo_controller.v (76269e771295fadcd0ddf160bee4556fdfa62e56) 및 검증 스냅샷 (28160c34522e47fbd961466651598da063bc74ae)을 조회하여 주석 차이만 확인. 형식적 등가 검증은 아님. 원본 변경 없음.
- DUT 6포트, 조합 연결 3개. 클록·리셋·FIFO 없음.

## 발견·수정
- 기존 RANDOM_IDLE은 randomize 반환값만 검사하고 생성 결과가 제약을 만족하는지 별도로 확인하지 않았다. IDLE의 데이터 범위·valid=0·ready=1 검사 및 CONSTRAINT_FAIL IDLE을 추가. 기존 STALL 검사는 유지.
- 부모 타입의 태스크 인자에 자식 객체를 전달하는 업캐스팅과 가상 메서드 동적 디스패치를 구분. POLYMORPHIC_STALL 로그 이름 유지, 별도 난수 생성으로 집계하지 않음.
- 제07장의 interface를 실제로 재사용하지 않는 독립 예제라는 점 명시. 제05~08장 공통 DUT 보존.
- 원본 전체 RTL, 전체 TB, 독립 폴더, XSIM 우선 실행 및 Verilator 대체 절차 제공. 시간 배분 제거.
- AMD UG900 2024.1 및 2026.1의 Test Bench Feature 표에서 rand, constraint inheritance, set membership, randomize, in-line constraints 지원 표기 확인. 실제 설치 버전의 실행은 미검증. https://docs.amd.com/r/2024.1-English/ug900-vivado-logic-simulation/Test-Bench-Feature
- Verilator 공식 설치 문서에서 Z3 해결기 필요 확인. https://verilator.org/guide/latest/install.html
- 스크립트 기본 Z3 확인 및 TIMESCALEMOD 경고만 제외. X/Z 검증에 대한 2상태 모델 한계 명시.
- TB 9b2ce80553fe390f00180c1bbc06014ba6042bcc, 스크립트 9cbb0bfc133d3e4326c7a51baa293c4a9d13e6e5.

## 독립 정적 계산
- data 20~7E: 95개. 부모 전체 허용 조합 380개, IDLE 및 STALL 허용 조합 각각 95개. 데이터 00과 printable 조건의 교집합은 없음.
- DIRECT_A 41/1/1, RANDOM_IDLE d/0/1, RANDOM_STALL e/1/0, POLYMORPHIC_STALL e/1/0. d,e는 허용 범위의 예시 변수. 마지막 두 사례는 같은 객체. 네 비교는 각 3개 출력 조건을 묶어 검사한다. 제약 및 실패 경로 별도. 실제 randomize, RTL 시뮬레이션 및 음성 시험은 수행하지 않음.
- SVG Chromium 단독 렌더 및 스크린샷 확인. 13개 text, 겹침 0, viewBox 초과 0. 원격 Blob 2a5581711e1178edeba4a273f9f3568151c50901 및 인라인 동일. 편집기 JSON 왕복 NOT_RUN.
- 원격 HTML 714212d6924c8afc089eac8171777e08687d142d, 전체 RTL/TB·8절·24장 탐색 데이터·INDEX 정적 검사 통과.

## 상태
- 원본 대조·입력 공간 계산·코드 정적 확인·SVG 단독 렌더·원격 재조회: PASS (해당 범위).
- RTL_SIM(XSIM/Verilator): NOT_RUN — 로컬 실행 도구 부재.
- 전체 HTML/모바일/Pages 접속 및 편집기 JSON: NOT_RUN.
