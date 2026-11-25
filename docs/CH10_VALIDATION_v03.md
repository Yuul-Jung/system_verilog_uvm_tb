# 제10장 v03 검증 기록

## 원본 매칭
- amd_soc_p2 04.2장 02·06절, p2_04_2_rtl_v02.html (f42a821b9a35572d0940c24d6781bafb8287f21e).
- 현행 legacy/part02_1/ch04/rtl/pwm_core.v 및 reference_rtl/pwm_core.v Blob e813f3fb107bd327054d11e0b397817b8e7bd813 동일. 원본 변경 없음. DUT 13포트, 공개 출력 6개. AXI·보드 제외.

## 수정 및 반례
- 리셋 직전 HIGH 선행 조건, 초기 및 동작 중 동기 리셋의 active_polarity 검사, 정상 경로 요청 3회·출력 검사 48회 카운트 확인을 추가.
- 요청 누락 모드의 10개 관찰에서 이전 정상 0% 상태(공개 period/duty/enable/polarity/pending/pwm)를 확인. 다른 상태 오류는 FAIL TIMEOUT_BASELINE으로 분리한다. 관찰 반전 모드는 기존대로 실제 pwm_out 정상 확인 후 전용 진단으로 종료.
- 조건부 VCD 및 Icarus -DVCD, 이전 생성 파형 정리. TB 06e99b301ec633ebdf122e5697c5edf6065d5253, 스크립트 25fdb2d95d5f3ba6af0623d2148ff28c5e89bdce.
- 원본 RTL/TB/실행 스크립트 전체, 독립 폴더 및 XSIM 우선 실행 절차 제공. UG900 공식 xsim -testplusarg 옵션 확인(https://docs.amd.com/r/2021.1-English/ug900-vivado-logic-simulation/xsim-Executable-Options). XSIM 종료 코드 전달 방식은 미확인으로 수동 확인 절차를 명시. Icarus 자동 시험은 정상 종료·정확한 완료 문자열, 부정 비정상 종료·전용 진단을 요구.
- 적용 대기 10클록은 고정 8클록 조건에서만 사용. request_duty의 pending 검사는 해당 요청 시점에서 유효하며 일반 임의 위상 요청에 대한 보장 아님. 시간 배분 제거.

## 독립 시간 계산 (RTL 실측 아님)
| 사례 | 요청 ns | 수락 ns | 반영 ns | 관찰 ns |
|---|---:|---:|---:|---|
| 0% | 20 | 25 | 85 | 96~246 |
| 100% | 250 | 255 | 325 | 336~486 |
| 리셋 후 100% | 510 | 515 | 575 | 586~736 |

- 8클록 경계와 테스트벤치 에지 대기를 독립적으로 계산. 정상 경로 3회 요청, 48회 비교, 736ns 종료. 486ns HIGH 이후 488ns 리셋 인가, 489ns LOW 관찰, 495ns 내부 동기 리셋, 496ns 상태 검사.
- 관찰 반전: 336ns 첫 100% 검사에서 DETECTED_INJECTED_FAULT 예상(이전 16회 완료). 요청 누락: 266~356ns 10회 대기 후 DETECTED_APPLY_TIMEOUT 예상(이전 16회 완료). 이 계산은 실제 SV 이벤트 스케줄러나 오류 주입 시뮬레이션이 아니다.
- SVG Chromium 단독 렌더 및 스크린샷 확인: 텍스트 17개, 겹침 0, viewBox 초과 0. 원격 SVG f8d15cc1401f36059e0b1aaa07fe9305603d3bb8와 렌더 원본 동일, HTML 인라인 일치. 편집기 JSON 미제작.
- 원격 HTML 89d6621b27590a46ee5e326fc88e1eca1832f9c0: 전체 RTL/TB/스크립트 문자 일치, 8절, 24장 탐색, INDEX 최신 링크, 중복 ID 없음, 예상/실측 구분, 배포 독립성 정적 확인.

## 판정
- 원본 매칭·독립 시간 계산·SVG 단독 렌더·원격 정적 검사: PASS (각 범위).
- RTL_SIM(XSIM/Icarus), 실제 오류 주입과 자동 실행 스크립트 실동작: NOT_RUN — 시뮬레이터 명령 부재.
- 전체 HTML·모바일·Pages 실제 접속 및 편집기 JSON 왕복: NOT_RUN.
