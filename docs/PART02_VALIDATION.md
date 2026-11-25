# 제2부(05~08장) 종합 검증

## 순서화 및 체계화
| 장 | 핵심 내용 | 자료 및 검증 구조 | 발행 |
|---|---|---|---|
| 05 | logic·bit·enum·struct | 단일 10비트 구조체, X 보존과 2상태 변환 | ch05_verification_types_v03.html |
| 06 | packed/unpacked·queue·package | 기대값 순서, 타입 분리, 큐 비교 | ch06_arrays_queues_packages_v03.html |
| 07 | interface·modport·clocking block | 6포트 묶음, 방향, 에지 직전 관찰/이후 구동 | ch07_interface_modport_clocking_v02.html |
| 08 | class·extends·constraint | 객체 생성, 제약 및 공통 태스크 | ch08_objects_constraints_v02.html |

## 적대적 검토 및 조치
- 네 장의 원본 DUT는 동일한 uart_echo_controller.v (28160c34522e47fbd961466651598da063bc74ae). UART 직렬 프레임, FIFO 및 클록 기반 내부 수락 회로를 검증한다고 오인하지 않도록 범위 명시.
- 제05장의 4상태 보존과 제06장의 큐 비교는 서로 다른 검사 목적. 제05·06장 구조체 필드 순서 차이를 제06장에 명시하고 독립 실습으로 구분.
- 제07장의 tb_clk은 TB 관찰용이며 원본에 연결하지 않음. Z 문자는 5A이며 고임피던스 Z와 다름. 제08장에서는 클래스 개념을 분리하여 평면 포트로 구동하며 인터페이스를 재사용하는 것으로 설명하지 않음.
- 제08장 IDLE 생성 결과 검사 누락 보완. 두 STALL 검사는 하나의 자식 객체를 재사용한다는 점과 동적 디스패치 미구현 명시.
- 제05~07장 탐색 데이터의 구버전 링크를 최신화. 전체 INDEX와 제2부 4개 장의 24개 탐색 데이터 일치. 기존 URL 리다이렉트 유지.
- 각 장의 원본 전체 RTL 및 TB를 실제 원격 파일과 비교. 제06장 package, 제07장 interface 포함. 장마다 8절, 중복 ID 없음, 외부 원본 링크나 수업 시간 배분 없음. 모든 장에 독립 실습 절차와 예상/실측 구분 포함.
- 제05장 비트 계산, 제06장 큐 추적, 제07장 이벤트 모델, 제08장 제약 입력 공간 계산은 각 장 기록 참조. 실제 실행 로그가 아님.

## 판정
| 항목 | 상태 |
|---|---|
| 선수 관계 및 기술 범위 | 정적 검토 완료 |
| 전체 RTL/TB·의존 파일 일치 | PASS (4/4) |
| 설계 학습안내서 장·절 매칭 | PASS (4/4) |
| 좌측 탐색 데이터 및 INDEX | PASS (정적) |
| 장별 독립 계산 | PASS (계산 범위) |
| 장별 SVG 단독 렌더 | 기존 기록 및 제08장 렌더 결과 확인 |
| 실제 RTL_SIM | NOT_RUN |
| 전체 HTML·모바일·클릭·복사·Pages 실접속 | NOT_RUN |
| 편집기 JSON 왕복 | NOT_RUN |

원격 최종 HTML Blob:
- ch05_verification_types_v03.html: f76a5d866cce3dc91a6ed2eb052d211fae99ceec
- ch06_arrays_queues_packages_v03.html: 370d66310cbfc3c5ecfc886aa3aa56117f616921
- ch07_interface_modport_clocking_v02.html: 4b272ae0f8c7978e02c8f0f82b6c660ee091cdea
- ch08_objects_constraints_v02.html: 714212d6924c8afc089eac8171777e08687d142d

제2부 개정 및 정적 종합 검증 완료. 실제 컴파일/시뮬레이션 및 전체 페이지 검증은 미실행 상태로 유지한다. 제3부에서는 순차 PWM의 참조 모델 및 스코어보드로 확장한다.
