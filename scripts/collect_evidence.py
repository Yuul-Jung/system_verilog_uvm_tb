#!/usr/bin/env python3
"""24장 순차 실행과 공개 가능한 소스/로그 SHA256 증거를 보존한다."""

import argparse
import datetime as dt
import hashlib
import getpass
import json
from pathlib import Path
import re
import socket
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
KEY_LINE = re.compile(r"PASS|OBSERVATION ONLY|OBSERVED |DETECTED|UVM_FATAL.*\[|"
                      r"UVM_(ERROR|FATAL)\s*:|^POS |^EVENT |^t=|COVERAGE|REJECT")

# (추가) 승인 기준은 manifest의 자기 선언이 아니라 실제 장별 실행 계약이다.
NORMAL_RESULTS = {
    1: {"output.log": "=== CH01 END: OBSERVATION ONLY ==="},
    2: {"output.log": "=== CH02 END: OBSERVATION ONLY ==="},
    3: {"output.log": "=== CH03 END: OBSERVATION ONLY ==="},
    4: {"output.log": "PASS checks=11 errors=0"},
    5: {"output.log": "PASS checks=6 failures=0"},
    6: {"output.log": "PASS checks=11 failures=0 queue=0"},
    7: {"output.log": "CH07 PASS: 4 cases checked"},
    8: {"output.log": "CH08 PASS: 4 cases checked"},
    9: {"output.log": "PASS CH09 score_cycles=72 scenarios=6"},
    10: {"normal.log": "PASS CH10 requests=3 checks=48"},
    11: {"ch11.log": "PASS CH11 SVA checks=4"},
    12: {"output.log": "PASS CH12 cases=12 coverage=100.00%"},
    13: {"simulation.log": "PASS CH13 accepted=3 checks=14"},
    14: {"simulation.log": "PASS CH14 tx=18 rx=16+17 overrun=1 reset=1"},
    15: {"simulation.log": "PASS CH15 commits=7 checks=18"},
    16: {"simulation.log": "PASS CH16 cycles=21 basic_valid=12 pipe_valid=10"},
    17: {"normal.log": "PASS CH17 checks=8"},
    18: {"normal.log": "PASS CH18 checks=3 samples=24"},
    19: {"normal.log": "PASS CH19 requests=3 applied=3 samples=24"},
    20: {"normal.log": "PASS CH20 factory=traced plan=2,6,0 applied=3 samples=24",
         "alt.log": "PASS CH20 factory=traced plan=1,8,3 applied=3 samples=24"},
    21: {"normal.log": "PASS CH21 RAL reads=7 writes=3"},
    22: {"normal.log": "PASS CH22 AXI_W=6 AXI_R=13 IRQ=4 RESET=2 COLLISION=1 ZERO=1"},
    23: {"simulation.log": "PASS CH23 cases=8 rejected=4"},
    24: {"seed_1.log": "PASS CH24 seed=1 checks=32 accepted=9",
         "seed_7.log": "PASS CH24 seed=7 checks=32 accepted=11",
         "seed_42.log": "PASS CH24 seed=42 checks=32 accepted=9"},
}
NEGATIVE_RESULTS = {
    (10, "fault"): ("fault_injection.log", r"FATAL: .*DETECTED_INJECTED_FAULT dut=1 measured=0"),
    (10, "timeout"): ("apply_timeout.log", r"FATAL: .*DETECTED_APPLY_TIMEOUT duty=8 deadline=10clks"),
    (11, "sva"): ("ch11_negative.log", r"Fatal: DETECTED_SVA_PENDING t=55"),
    (17, "NO_VIF"): ("negative.log", r"UVM_FATAL\b.*\[NOVIF\] pwm_if was not provided"),
    (18, "INVALID_DUTY"): ("negative.log", r"UVM_FATAL\b.*\[INVALID_DUTY\] duty=9 completed=1"),
    (19, "CORRUPT_SAMPLE"): ("negative.log", r"UVM_FATAL\b.*\[SB_PWM\] t=126 phase=2 expected=0 got=1"),
    (20, "NO_OVERRIDE"): ("NO_OVERRIDE.log", r"UVM_FATAL\b.*\[FACTORY\] Driver type override was ignored"),
    (20, "NO_CFG"): ("NO_CFG.log", r"UVM_FATAL\b.*\[NO_CFG\] Driver config not found"),
    (20, "EARLY_DROP"): ("EARLY_DROP.log", r"UVM_FATAL\b.*\[COUNTS\] Incomplete verification samples=17"),
    (21, "NO_PREDICT"): ("negative.log", r"UVM_FATAL\b.*\[PREDICT_WRITE\] addr=00000010 expected=11223344"),
    (22, "CORRUPT_IRQ"): ("negative.log", r"UVM_FATAL\b.*\[IRQ_MISMATCH\] status=10 expected=11 collisions=1"),
    (24, "fault"): ("negative.log", r"FATAL: .*DETECTED_INJECTED_FAULT case=9"),
}
# (변경) Verilator 형식(`%Error`, `[120] %Fatal`)과 들여 쓴 FAIL 행도 실패로 본다.
NORMAL_FAILURE = (r"^\s*(?:FATAL:|Fatal:|FAIL\b|ERROR:|Error:|UVM_(?:ERROR|FATAL)\b(?!\s*:))"
                  r"|^(?:\[[^\]\n]*\]\s*)?%(?:Error|Fatal)\b")
# (추가) 실행 후 바뀐 소스는 이 기록에 실행 당시/현재 해시와 재검증 범위를 남긴다.
POST_RUN_CHANGES = ROOT / "docs/evidence/POST_RUN_CHANGES_v59.json"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def sanitize(text):
    text = text.replace(str(ROOT), "<REPO>")
    text = re.sub(r"/home/[^\s\"'<>:]+", "<PRIVATE_PATH>", text)
    text = re.sub(r"/tmp/[^\s\"'<>:]+", "<TEMP_PATH>", text)
    text = re.sub(r"[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}", "<EMAIL>", text)
    text = re.sub(r"\b(?:gh[pousr]_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+)\b", "<TOKEN>", text)
    # XCRG HTML과 shell trace에도 계정명·호스트명이 들어갈 수 있다.
    # (변경) 계정명은 경로·이메일·환경변수처럼 계정을 식별하는 문맥에서만 지운다.
    # 단어 단위 전역 치환은 계정명이 root·user처럼 흔한 단어일 때 본문을 훼손한다.
    host = re.escape(socket.gethostname())
    if host:
        text = re.sub(rf"(?<![\w.-]){host}(?![\w-])", "[HOST]", text)
    user = re.escape(getpass.getuser())
    text = re.sub(rf"(?<=[/\\]){user}(?=[/\\\s\"':]|$)", "[USER]", text, flags=re.M)
    text = re.sub(rf"(?<![\w.-]){user}(?=@)", "[USER]", text)
    text = re.sub(rf"\b(USER|LOGNAME|USERNAME|HOME)=([^\s]*){user}\b", r"\1=\2[USER]", text)
    return text


def publish(source, target, bundle):
    raw = source.read_bytes()
    public = sanitize(raw.decode("utf-8", errors="replace")).encode()
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(public)
    return dict(local_path=source.relative_to(ROOT).as_posix(),
                public_path=target.relative_to(bundle).as_posix(),
                raw_sha256=sha(raw), public_sha256=sha(public), bytes=len(public))


def build_dir(number):
    parent = ROOT / f".build/ch{number:02d}"
    if number in (12, 17, 18, 19, 20, 21, 22, 24):
        return max(parent.glob("run*"), key=lambda p: p.stat().st_mtime)
    return parent / "xsim" if number == 11 else parent


def log_names(number):
    if number < 7 or number == 9:
        names = ["output.log"]
    elif number in (7, 8):
        names = ["output.log", "build.log", "tool_version.txt"]
    elif number == 10:
        names = ["normal.log", "fault_injection.log", "apply_timeout.log"]
    elif number == 11:
        names = ["ch11.log", "ch11_negative.log"]
    elif number == 12:
        names = ["output.log", "xcrg.log", "report/functionalCoverageReport/dashboard.html",
                 "report/functionalCoverageReport/groups.html",
                 "report/functionalCoverageReport/grp0.html"]
    elif number in (17, 18, 19, 21, 22):
        names = ["normal.log", "negative.log", "elaborate.log"]
    elif number == 20:
        names = ["normal.log", "alt.log", "NO_OVERRIDE.log", "NO_CFG.log", "EARLY_DROP.log"]
    elif number == 24:
        names = ["compile.log", "seed_1.log", "seed_7.log", "seed_42.log", "negative.log", "report.json"]
    else:
        names = ["simulation.log"]
    return names


def log_files(number, folder):
    return [folder / name for name in log_names(number) if (folder / name).is_file()]


def required_sources():
    chapters = json.loads((ROOT / "course.json").read_text())["chapters"]
    sources = {ROOT / c["source"] for c in chapters}
    if len(chapters) != 24 or len(sources) != 24:
        raise ValueError("course.json must identify 24 primary TB files")
    # 파일이 삭제되어도 필수 집합에서 사라지지 않도록 경로를 먼저 정의한다.
    rtl = ("axi4lite_slave_adapter.v custom_register_bank.v dsp_multiplier.v mac_core.v "
           "mac_pipeline_core.v npu_dsp_mac_lane.v npu_engine4.v pwm_core.v uart_core.v "
           "uart_echo_controller.v uart_rx.v uart_tx.v").split()
    sources.update(ROOT / "reference_rtl" / name for name in rtl)
    sources.update(ROOT / (f"tb/ch{n:02d}/run_ch{n:02d}.sh" if n in (11, 12)
                           else f"scripts/run_ch{n:02d}.sh") for n in range(1, 25))
    sources.update(ROOT / name for name in (
        "scripts/setup_env.sh", "scripts/run_chapter.sh", "scripts/run_ch24.py",
        "scripts/ch16_reference.py", "tb/ch06/uart_expect_pkg.sv",
        "tb/ch07/uart_stream_if.sv", "tb/ch09/pwm_reference_model.sv"))
    return sorted(sources)


def negative_diagnostic(number, name, text):
    pattern = NEGATIVE_RESULTS[number, name][1]
    diagnostics = re.findall(r"^(?:FATAL:|Fatal:|UVM_FATAL\b(?!\s*:))[^\n]*", text, re.M)
    if 17 <= number <= 22:
        for severity, expected in (("ERROR", "0"), ("FATAL", "1")):
            if re.findall(rf"^UVM_{severity}\s*:\s*(\d+)\s*$", text, re.M) != [expected]:
                return False
    return (len(diagnostics) == 1 and re.fullmatch(pattern + r"\s*", diagnostics[0]) is not None
            and not re.search(rf"\bPASS CH{number:02d}\b|\bCH{number:02d} PASS:", text)
            and not re.search(r"^(?:FAIL\b|ERROR:|Error:|UVM_ERROR\b(?!\s*:))", text, re.M))


def negative_exit(number, code):
    # XSIM의 Fatal은 버전에 따라 0 또는 1, Icarus의 주입 시험은 반드시 1이다.
    return type(code) is int and code in ((1,) if number in (10, 24) else (0, 1))


def snapshot_logs(number, bundle, prefix):
    folder = build_dir(number)
    records = []
    for source in log_files(number, folder):
        name = source.relative_to(folder).as_posix()
        records.append(publish(source, bundle / prefix / f"ch{number:02d}" / name, bundle))
    return records


def post_run_changes():
    """실행 이후 의도적으로 바뀐 소스. 해시 불일치는 이 기록과 정확히 일치할 때만 허용한다."""
    if not POST_RUN_CHANGES.is_file():
        return {}
    records = json.loads(POST_RUN_CHANGES.read_text())["changes"]
    return {r["path"]: r for r in records}


def verify(bundle):
    failures = []
    changed = post_run_changes()
    accepted_changes = set()

    def source_matches(name, recorded):
        path = relative_file(ROOT, name)
        if not path.is_file():
            return False
        current = sha(path.read_bytes())
        if current == recorded:
            return True
        change = changed.get(name)
        if change and change.get("run_sha256") == recorded and change.get("current_sha256") == current:
            accepted_changes.add(name)
            return True
        return False

    def relative_file(base, name):
        path = base / name
        if Path(name).is_absolute() or not path.resolve().is_relative_to(base.resolve()):
            raise ValueError("file path escapes evidence/source root")
        return path

    def checked_log(record):
        name = record["public_path"]
        path = relative_file(bundle, name)
        if not path.is_file():
            failures.append(f"missing log: {name}")
            return ""
        data = path.read_bytes()
        if sha(data) != record["public_sha256"]:
            failures.append(f"log SHA256: {name}")
        return data.decode("utf-8", errors="replace")

    try:
        manifest = json.loads((bundle / "manifest.json").read_text())
        chapters = manifest["chapters"]
        ids = [c["chapter"] for c in chapters]
        if (len(ids) != 24 or any(type(n) is not int for n in ids)
                or set(ids) != set(range(1, 25))):
            failures.append("chapters must contain 01..24 exactly once")
        current_logs = {}
        for chapter in chapters:
            number = chapter["chapter"]
            if type(number) is not int or number not in NORMAL_RESULTS:
                failures.append("invalid chapter ID")
                continue
            status = "EXECUTED_OBSERVATION" if number <= 3 else "PASS"
            if (chapter.get("status") != status or type(chapter.get("exit_code")) is not int
                    or chapter["exit_code"] != 0):
                failures.append(f"CH{number:02d}: invalid status/exit_code")
            logs = {r["public_path"]: checked_log(r) for r in chapter["logs"]}
            if len(logs) != len(chapter["logs"]):
                failures.append(f"CH{number:02d}: duplicate log path")
            current_logs.update(logs)
            prefix = f"runs/ch{number:02d}/"
            for name in log_names(number) + ["runner.txt"]:
                if prefix + name not in logs:
                    failures.append(f"missing required log: {prefix + name}")
                elif name not in ("compile.log", "build.log") and not logs[prefix + name].strip():
                    failures.append(f"empty required log: {prefix + name}")
            for name, marker in NORMAL_RESULTS[number].items():
                text = logs.get(prefix + name, "")
                start = r"^UVM_INFO\b[^\n]*\[RESULT\]\s+" if 17 <= number <= 22 else "^"
                # (변경) 완료 행은 정확히 한 번만 허용한다. 이어 붙인 로그를 막는다.
                if (len(re.findall(start + re.escape(marker) + r"\s*$", text, re.M)) != 1
                        or re.search(NORMAL_FAILURE, text, re.M)):
                    failures.append(f"CH{number:02d}: normal completion/diagnostic: {name}")
                if 17 <= number <= 22:
                    for severity in ("ERROR", "FATAL"):
                        counts = re.findall(rf"^UVM_{severity}\s*:\s*(\d+)\s*$", text, re.M)
                        if counts != ["0"]:
                            failures.append(f"CH{number:02d}: UVM_{severity} not zero: {name}")
            for record in chapter.get("legacy_logs", []):
                checked_log(record)

        cases = manifest.get("case_probes", [])
        keys = [(c["chapter"], c["name"]) for c in cases]
        if (len(keys) != 12 or any(type(n) is not int for n, _ in keys)
                or set(keys) != set(NEGATIVE_RESULTS)):
            failures.append("case_probes must contain all 12 dedicated cases exactly once")
        probe_paths = []
        for case in cases:
            number, name = case["chapter"], case["name"]
            if type(number) is not int or (number, name) not in NEGATIVE_RESULTS:
                failures.append("unknown negative case")
                continue
            text = checked_log(case["log"])
            path = case["log"]["public_path"]
            probe_paths.append(path)
            if path != f"probes/ch{number:02d}_{name}.txt":
                failures.append(f"negative log path: CH{number:02d}/{name}")
            if (case.get("status") != "PASS_NEG" or not negative_exit(number, case.get("exit_code"))
                    or not negative_diagnostic(number, name, text)):
                failures.append(f"negative status/exit/diagnostic: CH{number:02d}/{name}")
        if len(probe_paths) != len(set(probe_paths)):
            failures.append("duplicate negative log path")
        for (number, name), (log_name, _) in NEGATIVE_RESULTS.items():
            if not negative_diagnostic(number, name, current_logs.get(f"runs/ch{number:02d}/{log_name}", "")):
                failures.append(f"suite negative diagnostic: CH{number:02d}/{name}")

        report = json.loads(current_logs.get("runs/ch24/report.json", "{}"))
        expected = {"seed_1": 0, "seed_7": 0, "seed_42": 0, "negative_injection": 1}
        report_cases = report.get("cases", [])
        if (report.get("status") != "PASS" or report.get("seeds") != [1, 7, 42]
                or len(report_cases) != 4 or {c["name"] for c in report_cases} != set(expected)
                or any(c.get("status") != "PASS" or type(c.get("exit_code")) is not int
                       or c["exit_code"] != expected[c["name"]] for c in report_cases)):
            failures.append("CH24: incomplete/failed report.json")

        sources = manifest["sources_sha256"]
        required = {p.relative_to(ROOT).as_posix() for p in required_sources()}
        if not required or not required.issubset(sources):
            failures.append("missing required sources_sha256 entries")
        for name, digest in sources.items():
            if not source_matches(name, digest):
                failures.append(f"source SHA256: {name}")
        audit = bundle / "audit_sources.json"
        if audit.is_file():
            for name, digest in json.loads(audit.read_text())["files_sha256"].items():
                if not source_matches(name, digest):
                    failures.append(f"audit source SHA256: {name}")
        # (추가) 공개 체크섬 목록도 직접 대조한다.
        sums = bundle / "SHA256SUMS"
        if sums.is_file():
            for line in sums.read_text().splitlines():
                digest, _, name = line.partition("  ")
                path = relative_file(bundle, name)
                if not path.is_file() or sha(path.read_bytes()) != digest:
                    failures.append(f"SHA256SUMS: {name}")
    except (OSError, ValueError, KeyError, TypeError, AttributeError) as exc:
        failures.append(f"malformed/incomplete evidence: {sanitize(str(exc))}")
    if failures:
        print("FAIL evidence: " + ", ".join(failures))
        return 1
    print("PASS evidence: 24 chapters, 12 negative cases, required sources/logs and SHA256")
    if accepted_changes:
        chapters = sorted({c for n in accepted_changes for c in changed[n].get("chapters", [])})
        print(f"NOTE post-run source changes: {len(accepted_changes)} files recorded in "
              f"{POST_RUN_CHANGES.relative_to(ROOT).as_posix()}; affected chapters: "
              + (", ".join(f"CH{c:02d}" for c in chapters) or "none"))
    return 0


def probe_cases(bundle):
    manifest = json.loads((bundle / "manifest.json").read_text())
    specs = [(10, "fault", ["vvp", "./sim.vvp", "+INJECT_FAULT"], "DETECTED_INJECTED_FAULT"),
             (10, "timeout", ["vvp", "./sim.vvp", "+INJECT_TIMEOUT"], "DETECTED_APPLY_TIMEOUT"),
             (11, "sva", ["xsim", "ch11_sim", "-runall", "-onerror", "quit", "-testplusarg", "INJECT_SVA_PENDING"], "DETECTED_SVA_PENDING t=55")]
    for n, arg, marker in ((17, "NO_VIF", "[NOVIF]"), (18, "INVALID_DUTY", "[INVALID_DUTY]"),
                            (19, "CORRUPT_SAMPLE", "[SB_PWM]"), (20, "NO_OVERRIDE", "[FACTORY]"),
                            (20, "NO_CFG", "[NO_CFG]"), (20, "EARLY_DROP", "[COUNTS]"),
                            (21, "NO_PREDICT", "[PREDICT_WRITE]"), (22, "CORRUPT_IRQ", "[IRQ_MISMATCH]")):
        specs.append((n, arg, ["xsim", f"ch{n}_sim", "-runall", "-onerror", "quit", "-testplusarg", arg], marker))
    specs.append((24, "fault", ["vvp", "sim", "+SEED=1", "+INJECT_FAULT"], "DETECTED_INJECTED_FAULT case=9"))
    private = Path(tempfile.mkdtemp(prefix="case_probes_", dir=ROOT / ".build"))
    cases = []
    for n, name, command, marker in specs:
        folder = build_dir(n)
        result = subprocess.run(["bash", "-c",
                                 'source scripts/setup_env.sh >/dev/null; cd "$1"; shift; exec "$@"',
                                 "probe", str(folder), *command], cwd=ROOT,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
        path = private / f"ch{n:02d}_{name}.txt"
        path.write_bytes(result.stdout)
        text = result.stdout.decode(errors="replace")
        passed = negative_exit(n, result.returncode) and negative_diagnostic(n, name, text)
        cases.append(dict(chapter=n, name=name, command=command,
                          cwd=folder.relative_to(ROOT).as_posix(), exit_code=result.returncode,
                          expected_marker=marker, status="PASS_NEG" if passed else "FAIL",
                          log=publish(path, bundle / "probes" / path.name, bundle)))
        print(f"CH{n:02d} {name} {cases[-1]['status']} exit={result.returncode}", flush=True)
    manifest["case_probes"] = cases
    (bundle / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    return 0 if all(c["status"] == "PASS_NEG" for c in cases) else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "docs/evidence/v59")
    parser.add_argument("--verify", action="store_true")
    parser.add_argument("--probes", action="store_true", help="보존된 빌드로 12개 부정 시험 종료 코드 재측정")
    args = parser.parse_args()
    bundle = args.output.resolve()
    if args.verify:
        return verify(bundle)
    if args.probes:
        return probe_cases(bundle)
    bundle.mkdir(parents=True, exist_ok=False)
    raw_dir = Path(tempfile.mkdtemp(prefix="evidence_v59_", dir=ROOT / ".build"))
    sources = required_sources()
    manifest = dict(schema=1, base_commit=subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
        created_utc=dt.datetime.now(dt.timezone.utc).isoformat(),
        sources_sha256={p.relative_to(ROOT).as_posix(): sha(p.read_bytes()) for p in sources},
        tools={}, chapters=[])
    # 과거 종료 코드는 로그에 없는 경우 복원할 수 없으므로 별도로 명시한다.
    legacy = {n: snapshot_logs(n, bundle, "legacy") for n in range(1, 25)}
    for n in range(1, 25):
        started = dt.datetime.now(dt.timezone.utc).isoformat()
        raw_log = raw_dir / f"ch{n:02d}.txt"
        command = ["bash", "-x", "scripts/run_chapter.sh", f"{n:02d}"]
        # -x는 shell이 실제 실행한 명령을 보존한다. 전체 환경 값은 수집하지 않는다.
        with raw_log.open("wb") as stream:
            result = subprocess.run(command,
                                    cwd=ROOT, stdout=stream, stderr=subprocess.STDOUT,
                                    timeout=300, check=False)
        logs = snapshot_logs(n, bundle, "runs")
        runner = publish(raw_log, bundle / "runs" / f"ch{n:02d}" / "runner.txt", bundle)
        logs.append(runner)
        key = []
        for record in logs[:-1]:
            path = bundle / record["public_path"]
            if path.suffix not in (".log", ".txt") or path.name == "build.log":
                continue
            for line in path.read_text().splitlines():
                if KEY_LINE.search(line):
                    key.append(dict(log=record["public_path"], text=line))
        chapter = dict(chapter=n, command=command, cwd="<REPO>", started_utc=started,
                       exit_code=result.returncode,
                       status=("EXECUTED_OBSERVATION" if n <= 3 else "PASS")
                       if result.returncode == 0 else "FAIL",
                       legacy_exit_code="NOT_RECORDED", legacy_logs=legacy[n], logs=logs,
                       key_log=key)
        manifest["chapters"].append(chapter)
        (bundle / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
        print(f"CH{n:02d} {chapter['status']} exit={result.returncode} logs={len(logs)}", flush=True)
        if result.returncode:
            return 1
    versions = subprocess.run(["bash", "-c", "source scripts/setup_env.sh >/dev/null; "
                              "iverilog -V 2>&1 | head -1; verilator --version; "
                              "z3 --version; python3 --version; xvlog --version | head -1"],
                             cwd=ROOT, capture_output=True, text=True, check=False)
    manifest["tools"]["version_output"] = sanitize(versions.stdout)
    (bundle / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    if probe_cases(bundle):
        return 1
    return verify(bundle)


if __name__ == "__main__":
    raise SystemExit(main())
