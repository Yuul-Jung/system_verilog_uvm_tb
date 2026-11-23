> 이전 기록: 이 문서는 `amd_soc_rtl/system_verilog_uvm_tb`에서 작성한 당시의 검증 기록을 옮긴 것입니다. 독립 저장소 이관 후의 새 검증 결과는 `docs/MIGRATION_v01.md`를 참조하세요. 실제 시뮬레이션 미실행 상태는 그대로 유지됩니다.

# HTML 교육과정 좌측 탐색 체계 · 검증 v01

## 결정
- 최상위는 **PART(부)**, 중간은 **CHAPTER(장)**, 하위는 **SECTION(절)**이다.
- 기존 INDEX의 `제1부~제6부`와 장 카드(24개) 구성 자체는 의미적으로 올바르다.
- 문제는 좌측 공통 메뉴에서 PART가 표시되지 않고 전체 장을 평면으로 나열하던 점이었다.

## 수정 내용
- 현재 장의 PART를 좌측 상단에 **정확히 한 번** 표시한다. PART 제목은 `CURRICULUM.md`의 6부와 일치한다.
- 현재 PART에 속한 CHAPTER만 장 목록으로 제공한다(각 부 4장 예정, 미발행 장은 제외).
- 현재 CHAPTER의 SECTION은 현재 장 바로 밑에 들여써 표시한다.
- INDEX에서는 `ALL 6 PARTS`를 한 번만 표시한다. INDEX 본문에 전체 6부/24장 편성을 유지한다.
- 기존 `rule_md` 디자인, CSS 기본 규칙, 코드 복사, 모바일 탐색, 키보드 Escape, 이전/다음 장 링크를 유지한다.

## 테스트 증거와 한계
| 항목 | 결과 | 근거 |
|---|---|---|
| HTML 파일·기존 목차 정적 확인 | PASS | GitHub INDEX, course.json, ch01~06 확인 |
| JavaScript 구문·DOM 실행 모의 테스트 | PASS | 사용자 입력에 해당하는 PART 01/02/INDEX 3개 케이스, 생성 노드/링크 확인 |
| 제03장 좌측 PART 표시 개수 | PASS(모의) | PART 01 **1개** |
| 제03장 CHAPTER 범위 | PASS(모의) | CH01~04(4개) |
| 제03장 SECTION 위치·수 | PASS(모의) | CH03 하위 9절 |
| 제05장 PART/장 범위 | PASS(모의) | PART 02 **1개**, 발행된 CH05~06만 표시 |
| INDEX 장별 탐색 | PASS(모의) | 현재 발행 CH01~06 확인 |
| 이전/다음·코드 복사·Escape 코드 보존 | PASS(정적) | 수정 후 assets/site.js 소스 확인 |
| 실제 크로미움 화면·모바일 조작 | NOT_RUN | 실브라우저를 통한 렌더링 시험 미수행 |
| GitHub Pages 공개 접속 | NOT_RUN | 공개 사이트 HTTP 접속 미검증 |

**주의:** 모의 DOM 실행은 JavaScript 탐색 동작을 검증하지만 실제 브라우저 화면·GitHub Pages 배포 성공을 의미하지 않는다. RTL 원본과 기존 교육용 본문에는 변경 사항이 없다.

**저장소 링크:** `system_verilog_uvm_tb/index.html` · `assets/site.js` · `assets/site.css`.
