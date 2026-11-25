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


def sha(data):
    return hashlib.sha256(data).hexdigest()


def sanitize(text):
    text = text.replace(str(ROOT), "<REPO>")
    text = re.sub(r"/home/[^\s\"'<>:]+", "<PRIVATE_PATH>", text)
    text = re.sub(r"/tmp/[^\s\"'<>:]+", "<TEMP_PATH>", text)
    text = re.sub(r"[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}", "<EMAIL>", text)
    text = re.sub(r"\b(?:gh[pousr]_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+)\b", "<TOKEN>", text)
    # XCRG HTML과 shell trace에도 계정명·호스트명이 들어갈 수 있다.
    text = text.replace(socket.gethostname(), "[HOST]")
    text = re.sub(rf"\b{re.escape(getpass.getuser())}\b", "[USER]", text)
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


def log_files(number, folder):
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
    return [folder / name for name in names if (folder / name).is_file()]


def snapshot_logs(number, bundle, prefix):
    folder = build_dir(number)
    records = []
    for source in log_files(number, folder):
        name = source.relative_to(folder).as_posix()
        records.append(publish(source, bundle / prefix / f"ch{number:02d}" / name, bundle))
    return records


def verify(bundle):
    manifest = json.loads((bundle / "manifest.json").read_text())
    failures = []
    for chapter in manifest["chapters"]:
        for record in chapter["logs"] + chapter["legacy_logs"]:
            path = bundle / record["public_path"]
            if not path.is_file() or sha(path.read_bytes()) != record["public_sha256"]:
                failures.append(record["public_path"])
    for case in manifest.get("case_probes", []):
        record = case["log"]
        path = bundle / record["public_path"]
        if sha(path.read_bytes()) != record["public_sha256"]:
            failures.append(record["public_path"])
    for name, digest in manifest["sources_sha256"].items():
        if sha((ROOT / name).read_bytes()) != digest:
            failures.append(name)
    audit = bundle / "audit_sources.json"
    if audit.is_file():
        for name, digest in json.loads(audit.read_text())["files_sha256"].items():
            if sha((ROOT / name).read_bytes()) != digest:
                failures.append(name)
    if failures:
        print("FAIL evidence hashes: " + ", ".join(failures))
        return 1
    print(f"PASS evidence hashes: {len(manifest['chapters'])} chapters, sources and published logs")
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
        passed = marker in text and not re.search(rf"PASS CH{n:02d}\b", text)
        if n in (10, 24):
            passed = passed and result.returncode == 1
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
    sources = {p for directory in ("reference_rtl", "tb")
                      for p in (ROOT / directory).rglob("*")
                      if p.is_file() and p.suffix in (".v", ".sv", ".svh", ".sh")}
    sources.update((ROOT / "scripts").glob("run_ch[0-9][0-9].sh"))
    sources.update(ROOT / "scripts" / name for name in (
        "setup_env.sh", "run_chapter.sh", "run_ch24.py", "ch16_reference.py"))
    sources = sorted(sources)
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
    return verify(bundle)


if __name__ == "__main__":
    raise SystemExit(main())
