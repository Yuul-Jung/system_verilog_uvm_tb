# 독립 저장소 경로 정정 및 이전 검증 · v01

**확인 기준:** 2026-11-23  
**교육과정명:** system_verilog_uvm_tb (정상 철자)  
**실제 GitHub 저장소명:** `Yuul-Jung/system_velirog_uvm_tb` (`velirog` 철자 차이 확인)  
**최종 저장 위치:** 해당 독립 저장소 **최상위 루트**  
**이전 잘못된 위치:** `Yuul-Jung/amd_soc_rtl/system_verilog_uvm_tb/` (보존·향후 읽기 전용)

## 1. 이전 결과
| 종류 | 확인된 수 | 대상 위치 |
|---|---:|---|
| 배포용 INDEX | 1 | `index.html` |
| 발행된 장별 HTML | 7 | `ch01_...html` ~ `ch07_...html` |
| 공통 CSS·JavaScript | 2 | `assets/` |
| 교육과정 설정·운영 문서·Git 설정 | 7 | `README.md`, `AGENTS.md`, `CURRICULUM.md`, `course.json`, `source_manifest.md`, `.gitignore`, `.nojekyll` |
| RTL 원본 스냅샷 | 2 | `reference_rtl/` |
| 시뮬레이션 실행 스크립트 | 7 | `scripts/run_ch01.sh` ~ `run_ch07.sh` |
| SystemVerilog 소스 | 9 | `tb/ch01/` ~ `tb/ch07/` |
| 과거 검증 기록 | 8 | `docs/` |
| **이전 완료한 기존 파일** | **43** | **저장소 최상위 이하** |

이 문서 `docs/MIGRATION_v01.md`를 더하면 총 44개입니다.

## 2. 반드시 유지할 원칙
- **신규 커밋·푸시는 독립 저장소 루트에만 수행**한다. `amd_soc_rtl` 내부 과거 사본은 신규 쓰기 대상이 아니다.
- 독립 실행을 위해 DUT 스냅샷 2개를 추가했지만 **RTL 코드를 변경하지 않았다.**
- 스크립트 기본 DUT 참조는 `reference_rtl/`이며, 외부 원본을 직접 검증할 때만 `DUT_PATH` 환경변수를 사용한다.
- 학습안내서 좌측 메뉴는 PART(부) → CHAPTER(장) → SECTION(절) 순서로 유지한다.
- 모든 HTML에는 정본 `rule_md/web/education-html/STANDARD.md` 디자인을 적용한다.
- 이전 저장소의 중복 파일은 원본 손상 방지를 위해 이관 완료 직후 삭제하지 않았다. 향후 새 파일을 추가하지 않는다.

## 3. 소스 무결성
| 파일 | 원본 Git Blob SHA | 이관한 복사본 SHA | 결과 |
|---|---|---|---|
| `reference_rtl/uart_echo_controller.v` | `28160c34522e47fbd961466651598da063bc74ae` | 동일 | 통과 |
| `reference_rtl/pwm_core.v` | `e813f3fb107bd327054d11e0b397817b8e7bd813` | 동일 | 통과 |

**Git Blob SHA 일치는 바이트 내용까지 동일하다는 의미**다.

## 4. 이전 검증 결과
| 점검 | 결과 | 확인 근거 |
|---|---|---|
| 독립 저장소 존재·쓰기가능 | 통과 | 원격 기본 브랜치 `main`에 커밋 성공 |
| `index.html`은 저장소 최상위 | 통과 | GitHub 파일 조회 |
| INDEX 장별 링크 7개와 course.json 7개 | 통과 | 파일명과 버전 1:1 대조 |
| INDEX의 6부 구성 | 통과 | HTML의 `제1~6부` 확인 |
| HTML 7장: `main` 및 `section` | 통과(정적) | 본문 구조·중복 ID 검사 |
| 모든 HTML의 CSS·JavaScript 참조 | 통과(정적) | `assets/site.css`, `assets/site.js` 상대경로 확인 |
| 좌측 메뉴 PART → CHAPTER → SECTION 코드 | 통과(정적) | 중첩·부별 필터 코드 확인 |
| TB 총 9개·스크립트 7개 경로 | 통과(정적) | 파일 존재·경로 대조 |
| 스크립트 기본 DUT 경로 | 통과(정적) | 모두 `reference_rtl/` 경로 사용 |
| DUT 원본 2개 SHA | 통과 | GitHub 원본 Blob SHA와 동일 |
| SystemVerilog 컴파일 및 RTL 시뮬레이션 | **NOT_RUN** | 확인 환경에 `iverilog`·`verilator` 실행기 없음 |
| HTML 실브라우저 렌더링·코드 복사 | **NOT_RUN** | 실제 브라우저 조작 미실시 |
| GitHub Pages 실제 공개 접속 | **NOT_VERIFIED** | 별도의 Pages 활성화·HTTP 접속 확인 필요 |

## 5. 다음 운영 시 주의사항
- 현재 실제 GitHub 원격 저장소 이름은 `system_velirog_uvm_tb`이다. 이름을 정상 철자 `system_verilog_uvm_tb`로 바꾸려면 GitHub 저장소 Settings에서 이름 변경이 필요하다.
- 현재 저장소 이름으로 복제하되 로컬 폴더는 `system_verilog_uvm_tb`를 사용할 수 있다.

```bash
# 독립 저장소를 원하는 이름으로 복제한다.
git clone https://github.com/Yuul-Jung/system_velirog_uvm_tb.git system_verilog_uvm_tb

# 현재 위치로 이동한 뒤, 파이프라인 스크립트를 실행한다.
cd system_verilog_uvm_tb
bash scripts/run_ch01.sh
```

- 사용자 지시가 있을 때는 예약 작업보다 대화에서의 직접 작업을 우선한다. 예약 작업의 GitHub 대상도 독립 저장소의 루트로 수정하였다.
