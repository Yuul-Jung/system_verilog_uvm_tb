# 제1부(01~04장) 종합 검증

## 과정 연결
| 장 | 핵심 성과 | DUT | 최신 발행 |
|---|---|---|---|
| 01 | 조합회로 입출력 관찰 | uart_echo_controller.v | ch01_testbench_basics_v04.html |
| 02 | 순차회로 클록·리셋·경계 이해 | pwm_core.v | ch02_clock_reset_events_v03.html |
| 03 | task/function/반복문과 상태 대기 | pwm_core.v | ch03_reusable_stimulus_v03.html |
| 04 | 독립 기대값 비교·오류 처리 | pwm_core.v | ch04_pass_fail_automation_v03.html |

01장 단순 관찰에서 02장 시간 계약, 03장 입력 재사용, 04장 자동 판정으로 확장. PWM 원본 동일, 고정 8클록/10ns 기준 유지. 독립된 프로젝트이며 후속 장에서 이전 TB를 복사할 필요 없음.

## 결함 발견 및 수정
1. 01장 선행 설계 학습안내서 장·절 누락 → amd_soc_npu 1-1 UART 에코 참조 추가(v04). 현행 원본과 스냅샷 주석·공백 제외 코드 일치 재확인(형식적 등가검증 아님).
2. 02장 설계 저장소 이전에 따른 낡은 참조 → amd_soc_p2 04.2장으로 수정(v03).
3. 01~03장의 이전 장 버전 탐색 데이터 및 INDEX 03장 표시 버전 불일치 → 4개 장 및 INDEX의 최신 24장 탐색 데이터 동기화. 03·04장은 탐색 메타데이터만 유지보수, 본문 버전 유지. 이전 URL은 최신으로 리다이렉트(기존 일부 페이지의 링크는 리다이렉트 경유 가능).
4. 04장의 원본 전체 코드 선행 배치, XSIM 실행 경로, 예상 결과와 반례, 검사 한계를 보강. 원본 RTL 불변.
5. 01~04장의 원격 HTML 코드 블록을 현재 RTL·TB와 문자 대조하고 실제 일치 확인. 4개 장 각각 8절·24장 탐색·중복 ID 없음·정확한 설계 참조·시간 배분 제거·XSIM 명령·예상 표기 확인.
6. 01~04장 기존 예상 상태 기록 및 04장 독립 이벤트 계산으로 순차 자극 일관성 확인. 04장 HIGH 개수만으로 위상 오류를 검출할 수 없는 한계를 명시.

## 검증 상태
| 항목 | 결과 |
|---|---|
| 선수 관계·기술 범위·내용 중복 검토 | 정적 확인 |
| 원격 코드 블록과 실제 RTL/TB 일치 | PASS (4/4) |
| 장·절 및 24장 탐색 데이터 | PASS (4/4) |
| INDEX 링크 및 대상 버전 | PASS (정적, 실제 Pages 접근 아님) |
| 제04장 예상 이벤트 모델/반례 | PASS (계산 범위) |
| 제04장 SVG 단독 Chromium | PASS |
| 실제 RTL 시뮬레이션 | NOT_RUN |
| 전체 브라우저, 모바일, 클릭·복사, Pages 실접속 | NOT_RUN |
| 편집기 JSON 왕복 | NOT_RUN |

원격 파일 SHA:
- ch01_testbench_basics_v04.html: dd0a835b074838cc7bc8db8a1939c604835c799c
- ch02_clock_reset_events_v03.html: 53c0b72879614b82be05ba1804982a6d8c4b718f
- ch03_reusable_stimulus_v03.html: 1845eafb07a2349d0d613dbdfce42d0407b3d336
- ch04_pass_fail_automation_v03.html: ae5985b7d83c0e7b147a35f75d66778458af9bac
제1부 제작 및 정적 종합 검증 완료. 실행 환경 부재에 따른 실제 검증은 후속 전수검증 대상이며 통과로 처리하지 않는다.
