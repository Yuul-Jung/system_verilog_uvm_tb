# 실행 증거 완전성 검사 검증 v01

- 작업일: 2026-11-26 (Asia/Seoul)
- 기준 커밋: `6edf029` — [독립 적대적 검증 v59](INDEPENDENT_REVIEW_v59.md)의 V59-01 보완.
- 적용 규칙: 과정 `AGENTS.md`, 중앙 `rule_md`의 코드·Ponytail·방법론·공통 스타일 규칙. 중앙 규칙 기준은 `028248a19afc66e9aafdab393fbe0de10a3930ca`이다.
- 대상: [collect_evidence.py](../scripts/collect_evidence.py)의 승인 검사와 [반례 시험](../scripts/test_evidence_completeness.py). 외부 의존성을 추가하지 않았다.

## 1. 승인 기준

해시가 일치해도 아래 계약을 충족하지 못하면 `--verify`는 종료 코드 1을 반환한다. 정상 증거만 종료 코드 0을 반환한다.

| 검사 대상 | 필수 조건 |
|---|---|
| 장 목록 | 정수 ID 01~24가 정확히 한 번씩 존재. 순서는 승인 조건이 아니다. |
| 장별 상태·종료 코드 | CH01~03은 `EXECUTED_OBSERVATION`, CH04~24는 `PASS`, 모두 정수 종료 코드 0. `NOT_RUN`·`FAIL`은 승인하지 않는다. |
| 장별 로그 | `runs/chNN/`의 필수 정상·부정·보조 로그와 `runner.txt`가 모두 존재하고 경로가 중복되지 않아야 한다. 빈 출력이 정상인 `compile.log`·`build.log` 이외의 필수 로그는 비어 있으면 거절한다. |
| 정상 완료 | 실제 27개 정상·관찰 로그의 장별 정확한 완료 행과 오류 부재를 확인한다. UVM 정상 실행은 `UVM_ERROR`·`UVM_FATAL` 요약이 각각 0이어야 한다. |
| 부정 시험 목록 | CH10 fault/timeout, CH11 sva, CH17 NO_VIF, CH18 INVALID_DUTY, CH19 CORRUPT_SAMPLE, CH20 NO_OVERRIDE/NO_CFG/EARLY_DROP, CH21 NO_PREDICT, CH22 CORRUPT_IRQ, CH24 fault의 12개가 정확히 한 번씩 존재해야 한다. |
| 부정 시험 결과 | `PASS_NEG`, 허용 종료 코드, 독립적으로 정의한 전용 Fatal 진단 1개, 정상 PASS 부재를 모두 확인한다. UVM 부정 실행은 ERROR 0/FATAL 1이어야 한다. manifest의 `expected_marker` 자기 선언은 승인 근거로 사용하지 않는다. |
| 부정 종료 코드 | Icarus CH10·24는 1, XSIM CH11·17~22는 0 또는 1. XSIM의 Fatal 처리 차이를 허용하되 전용 진단을 반드시 확인한다. |
| 부정 로그 두 경로 | 별도 `probes/` 로그뿐 아니라 장별 실행 묶음에 보존된 부정 로그도 전용 진단을 확인한다. |
| CH24 보고서 | 정상 시드 1/7/42와 fault의 고유 4개 결과, 각 상태·종료 코드, 전체 PASS를 확인한다. |
| 소스·무결성 | 실제 실행 소스 67개의 필수 경로를 파일 존재 여부와 독립적으로 정의하고, 모두 기재·존재·SHA256 일치해야 한다. 모든 기재된 공개 로그와 보조 도구 소스 해시 검사도 유지한다. 경로가 증거/소스 루트 밖으로 벗어나면 거절한다. |

새 전체 수집은 24장 실행 후 12개 별도 부정 시험까지 수행한 다음 완전성 검사를 호출한다. `--verify`는 시뮬레이터를 실행하지 않고 보존 증거를 검사한다.

## 2. 실제 반례 결과

검토 당시 코드와 수정 코드를 각각 별도 프로세스의 전체 CLI로 실행했다. 아래 3개는 이전 코드의 거짓 통과를 재현한 결과다.

| 입력 | 이전 코드 종료 코드 | 수정 코드 종료 코드 |
|---|---:|---:|
| 빈 장·소스 목록 | 0 | 1 |
| FAIL·종료 코드 1인 장 1개, 빈 로그 | 0 | 1 |
| 같은 장을 24번 중복, 빈 로그 | 0 | 1 |
| 보존된 실제 v59 전체 증거 | — | 0 |

추가로 24개 장을 각각 누락하거나 실패로 바꾸기, 모든 필수 로그를 하나씩 누락하기, 12개 부정 시험을 각각 누락·잘못된 진단으로 바꾸기, 중복 ID·경로, 잘못된 종료 코드·상태, CH24 불완전 보고서를 검사했다. **로그를 바꾼 뒤 SHA256까지 다시 맞춘 반례**도 거절했다. 순서 변경, 선택적 과거 로그 제외, 허용된 XSIM 종료 코드 1은 정상으로 승인했다.

## 3. 로컬 터미널 실제 검증

아래는 이번 수정 후 실행한 결과다. 테스트 개수는 `unittest` 시험 메서드 기준이며 각 메서드는 여러 반례를 포함한다.

| 실행 명령 | 실제 결과 |
|---|---|
| `python3 scripts/test_evidence_completeness.py` | 종료 0, 20개 통과, 19.568초 |
| `python3 scripts/test_review_fixes.py` | 종료 0, 기존 회귀 시험 18개 통과, 1.565초 |
| `python3 scripts/collect_evidence.py --verify` | 종료 0, 24장·12개 부정 시험·필수 소스/로그·SHA256 통과 |
| `python3 scripts/validate_course.py` | 종료 0, 24장 링크·절·SVG 이름·TB 검사 통과 |
| `sha256sum -c SHA256SUMS` (작업 폴더 `docs/evidence/v59`) | 종료 0, 공개 파일 197개 일치 |
| `python3 -m py_compile scripts/collect_evidence.py scripts/test_evidence_completeness.py` | 종료 0 |
| `git diff --check` | 종료 0 |

완전성 시험 실제 출력의 요약:

```text
Ran 20 tests in 19.568s

OK
FULL_EVIDENCE empty: baseline=0 fixed=1
FULL_EVIDENCE failed_single: baseline=0 fixed=1
FULL_EVIDENCE duplicate_24: baseline=0 fixed=1
PASS evidence: 24 chapters, 12 negative cases, required sources/logs and SHA256
```

## 4. 보존 범위와 미실행 항목

기존 24장 HTML, 원본 RTL, TB, 장별 실행 스크립트, 환경 설정, 실제 실행 manifest·로그·파형은 수정하지 않았다. `audit_sources.json`에는 개정 검사기와 새 시험 파일의 현재 해시를 반영했고, `SHA256SUMS`는 이 보조 메타데이터의 해시 한 항목만 갱신했다. 대용량 `.build`는 커밋하지 않는다.

- **NOT_RUN:** 이번 수정에서 24장 시뮬레이션 재실행, 새 증거 전체 수집, 실제 브라우저 재검증은 수행하지 않았다. 이번 PASS는 보존된 실행 증거와 수정 검사기의 실제 검증 결과다.
- **선택적 개선 미적용:** V59-02의 실행별 경로 확정 및 환경 추적 축소는 이번 최소 수정에서 제외했다. 기존 수집기의 mtime 기반 로그 선택과 `bash -x` 환경 확장 기록 가능성은 남아 있으므로 새 증거 공개 전 별도 점검이 필요하다. 이 검사는 파일 내용·완전성을 검증하며 새 실행과 로그의 귀속 자체를 보증하지 않는다.

## 5. 최종 요청에 따른 실제 재검증

조회 당시 원격 main과 로컬 HEAD는 모두 `ed4f6f264176a7889db0b0f9c388e1527710d5e2`였다. 요청서의 `6edf029`는 독립 검토 기준이며, 필수 코드 수정은 이미 `ed4f6f2`에 반영되어 있다. 2026-11-26에 이 코드를 그대로 재검증하고 아래 실제 CLI 결과를 보존했다. 기존 교재의 버전은 증가시키지 않았다.

| 시험 조건 | 실제 결과 | 실제 종료 코드 |
|---|---|---:|
| 정상 v59 증거 | PASS | 0 |
| 검증 장 0개 | FAIL | 1 |
| 검증 장 23개 | FAIL | 1 |
| 제1장 24개 중복 | FAIL | 1 |
| 실패 상태가 포함된 증거 | FAIL | 1 |
| 정상 로그 누락 | FAIL | 1 |
| 부정 시험 누락 | FAIL | 1 |
| 부정 시험 중복 | FAIL | 1 |
| 전용 오류 메시지 불일치 | FAIL | 1 |
| 필수 소스 누락 | FAIL | 1 |
| 로그 해시 불일치 | FAIL | 1 |

- [기계 판독 결과](evidence/completeness_v01/adversarial_results.json): 11개 입력 조건별 실제 stdout·stderr·종료 코드, 검사기/기준 manifest SHA256, 추가 검증 5개 명령, 원본 보존 대조 결과, 자동 시험 로그의 SHA256을 보존한다. 오류 진단 반례는 로그를 바꾸고 해시도 다시 맞춰서 검사했다.
- [완전성 자동 시험 전체 출력](evidence/completeness_v01/test_evidence_completeness.txt): 20개 통과, 종료 0, 20.317초.
- [기존 회귀 시험 전체 출력](evidence/completeness_v01/test_review_fixes.txt): 18개 통과, 종료 0, 1.538초.
- 원본 증거 `docs/evidence/v59`의 공개 파일 197개 체크섬과 현재 소스 검사를 다시 통과했다. HTML·RTL·TB·장별 실행 스크립트·실측 manifest·로그·파형은 `6edf029`와 바이트 단위로 동일했다.

이번 추가 변경은 이 보고서와 별도 재검증 증거 3개 파일뿐이다. 필수 수정의 미해결 항목은 없으며, 제4절의 NOT_RUN 범위와 선택적 수집 경로·추적 개선의 제한은 유지한다.
