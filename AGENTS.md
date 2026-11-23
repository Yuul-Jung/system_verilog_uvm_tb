# system_verilog_uvm_tb 작업 규칙

1. 중앙 정본: https://github.com/Yuul-Jung/rule_md (특히 `AGENTS.md`).
2. HTML: https://github.com/Yuul-Jung/rule_md/blob/d1b8278d41fca8f5e3960736f3ac9d377e462fda/web/education-html/STANDARD.md
3. 코드: `code/code-development-rules.md`, `common/code-style-rules.md`, 구조도: `common/flowchart-rules.md`.
4. 원본 `part01/`, `part02*/`, `part03/`의 RTL·XPR·BD·테스트 및 기존 교재는 절대 수정하지 않는다.
5. 검증용 TB·스크립트는 독립 폴더에만 작성, 실제 DUT 포트와 정확히 일치시킨다.
6. 실행하지 않은 RTL_SIM은 반드시 NOT_RUN, 교육용 예상 출력은 실제 로그와 구별한다.
7. INDEX는 발행된 장만 링크, 계획된 장에 깨진 링크 금지. 각 장별 버전 `_vNN.html`.
8. 1장 2시간은 60분 단위 두 구간으로 구성, 코드·실행 결과·구문별 풀이·검증 순서 유지.
9. 민감정보·계정·로컬 절대경로·토큰·비공개 소스를 공개 결과물에 포함하지 않는다.

## 배포 HTML의 좌측 3계층 목차 (필수)
- **PART(부) → CHAPTER(장) → SECTION(절)** 순서로 표시한다. PART는 CHAPTER보다 상위, SECTION은 현재 CHAPTER 아래의 하위 목록이다.
- 각 장에서 **현재 PART를 좌측 상단에 한 번만 표시**한다. 같은 부에 속한 CHAPTER만 아래에 배치하고, 현재 CHAPTER 바로 아래에 해당 페이지의 SECTION을 들여써 표시한다.
- INDEX는 현재 PART가 없는 특수 페이지로서 `ALL 6 PARTS`를 한 번 표시하고, 본문에 6개 PART와 24개 CHAPTER 목차를 유지한다.
- 현재 부는 4장씩 소속한다: PART 01 = CH01~04, PART 02 = CH05~08, ... PART 06 = CH21~24. `CURRICULUM.md`의 부 제목과 좌측 제목을 반드시 일치시킨다.
- 기존 `assets/site.js`의 PART 계층·절 중첩, `assets/site.css`의 `.course-part-*`·`.course-nested-sections`는 중앙 `rule_md`를 동기화할 때도 임의 덮어쓰지 않는다. 중앙 교육용 기본 스타일을 보존한 **과정 전용 확장**이다.
- 이전/다음 장 이동, INDEX 복귀, 모바일 서랍, 절 스크롤 강조, 코드 복사는 계속 유지한다. 새 장 제작 후 좌측 **PART 한 개·동일 부 CHAPTER·현재 장 SECTION**을 함께 검증한다.

## 독립 저장소 위치(2026-11-23 확정)
- **모든 신규 커밋·푸시는 `Yuul-Jung/system_velirog_uvm_tb` 저장소 최상위 루트에만 수행한다.**
- `Yuul-Jung/amd_soc_rtl/system_verilog_uvm_tb/`는 과거 잘못 작성한 사본이며 신규 쓰기 금지.
- 원본 RTL은 현재 저장소의 `reference_rtl/` 스냅샷으로 읽되, 다른 버전이 필요하면 `DUT_PATH`로 외부 RTL을 참조한다.
- 기존 원본 두 파일은 변경하지 않는다. Blob SHA가 source_manifest.md와 일치하는지 검증한다.
- PART(부) → CHAPTER(장) → SECTION(절)의 좌측 계층, 6부 24장, 정본 rule_md 규칙을 유지한다.
- 원격 저장소 이름은 현재 `system_velirog_uvm_tb`(철자 주의). 사용자 의도는 `system_verilog_uvm_tb`이다.
