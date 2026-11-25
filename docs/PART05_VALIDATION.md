# 제5부(17~20장) 종합 적대적 검증

| 장 | 검증 축 | 최신 발행 |
|---|---|---|
| 17 | 최소 UVM 환경·vif·phase·전체 PWM 주기 | ch17_minimal_uvm_environment_v02.html |
| 18 | Sequence·Sequencer·Driver·item_done | ch18_sequence_driver_v02.html |
| 19 | 독립 Monitor·Agent·Scoreboard | ch19_monitor_agent_scoreboard_v03.html |
| 20 | Factory·Config DB·Objection 구성 정책 | ch20_factory_config_objection_v02.html |

## 순서와 계약
- 17장 env의 직접 자극과 검사를 18장에서 거래 생성/구동 분리로 확장한다. 18장의 Driver 내부 비교는 아직 독립 Monitor/Scoreboard가 아니다.
- 19장에서는 매 상승 에지 +1ns의 새 관찰 객체를 Analysis Port/Imp로 전달한다. 경과 클록 기반 기대 위상으로 PWM 설정과 실제 출력을 검증한다. 18장과 달리 Driver는 적용 직후 완료를 통지하므로 이후 요청 타이밍이 달라지는 것은 의도적이며 19·20장은 동일 시간 계약을 유지한다.
- 20장의 기존 이벤트 관찰로 퇴행하는 결함을 수정해 19장의 독립 비교 구조를 그대로 보존. Factory는 실제 생성 타입, Config DB는 필요한 경로에 설정 참조, Objection은 전체 관찰 완료에 책임을 둔다. 공유 설정과 DUT 독립 기대 모델의 차이 명시.
- 17장의 NO_VIF, 18장의 INVALID_DUTY, 19장의 CORRUPT_SAMPLE, 20장의 NO_OVERRIDE/NO_CFG/EARLY_DROP는 각각 검증 환경의 오류 경로를 겨냥한다. 실제 RTL 변이 시험이나 UVM 엔진 실행으로 해석하지 않는다.
- 네 장 모두 동일 원본 PWM RTL, 전체 TB/스크립트 수록, XSIM 내장 UVM 우선, check_phase 및 report_phase 판정 확인. 공통 CSS/JS와 원본 RTL 변경 없음.
- 17~19장의 이전 탐색 주소 동기화, 제20장 이전 URL 호환 처리. 현재 4개 HTML 8절, 24장 탐색 및 INDEX, 코드 원문·중복 ID·대표 민감 패턴 정적 검사 완료.
- 17~20장 개별 SVG 단독 렌더 기록 확인(20장 신규 실제 렌더). 전체 웹페이지와 모바일 상호작용은 미실행.
- 17/18장 적용 시점은 pending 해제 관찰에 따라 시작되므로 정확한 경계 시간 자체의 독립 강제는 19/20장에서 보완된다. 임의 PWM 주기·극성·겹치는 요청·동작 중 리셋 등의 완전한 검증은 범위 밖.

| 검증 | 판정 |
|---|---|
| 원본 및 배포 소스 일치 | 4/4 |
| UVM 구성·완료 계약·학습 순서 | 정적 검토 완료 |
| 독립 시간 계산 | 장별 범위 완료 |
| 제20장 Bash 문법/모의 판정 | 13/13 기대 일치 |
| 제20장 SVG 단독 렌더 | 23개 텍스트, 겹침·잘림 0 |
| 실제 RTL_SIM/UVM·실제 오류 변이 | NOT_RUN |
| 전체 HTML·모바일·Pages·편집기 JSON | NOT_RUN |

## 최종 원격 페이지
- ch17_minimal_uvm_environment_v02.html: 9d3b77a4344988994b9a5ff1a8c0b8e70d643732
- ch18_sequence_driver_v02.html: 657ead3f5a8bb79bf70dbd66be11f0c6e479a1ea
- ch19_monitor_agent_scoreboard_v03.html: 9fcf8c415634771c7b101e0521a548129b0d58ab
- ch20_factory_config_objection_v02.html: 30ea6eed343d181ec8cc50fef900f759a95ece78

제5부 개정 및 정적 종합 검증 완료. 실제 UVM 시뮬레이션은 미완료. 다음 대상 제21장 UVM 레지스터 추상화.
