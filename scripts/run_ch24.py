#!/usr/bin/env python3
"""제24장 회귀 실행기: 시드·음성 시험·JSON/Markdown 보고서 생성."""
import argparse
import datetime as dt
import json
import pathlib
import re
import shutil
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
DUT = ROOT / "reference_rtl" / "uart_echo_controller.v"
TB = ROOT / "tb" / "ch24" / "tb_uart_regression.sv"
BUILD = ROOT / ".build" / "ch24"
SEEDS = (1, 7, 42)
EXPECTED_BLOB = "28160c34522e47fbd961466651598da063bc74ae"


def execute(command, timeout=30):
    """종료 코드와 stdout/stderr를 합쳐 재현 가능한 로그로 반환한다."""
    try:
        p = subprocess.run(
            command, cwd=BUILD, capture_output=True,
            text=True, timeout=timeout, check=False
        )
        return p.returncode, p.stdout + p.stderr
    except subprocess.TimeoutExpired as exc:
        return 124, "TIMEOUT: " + str(exc)


def main():
    parser = argparse.ArgumentParser(description="UART 회귀 검증 보고서")
    parser.add_argument("--seeds", default="1,7,42",
                        help="쉼표로 구분한 정수 시드 목록")
    args = parser.parse_args()
    try:
        seeds = [int(s) for s in args.seeds.split(",")]
        if not seeds or len(seeds) != len(set(seeds)):
            raise ValueError("중복 또는 빈 시드")
    except ValueError as exc:
        parser.error(str(exc))

    BUILD.mkdir(parents=True, exist_ok=True)
    result = {
        "chapter": 24,
        "timestamp_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "dut_path": "reference_rtl/uart_echo_controller.v",
        "dut_blob_sha": EXPECTED_BLOB,
        "simulator": "Icarus Verilog",
        "seeds": seeds,
        "cases": [],
        "status": "NOT_RUN",
    }
    available = bool(shutil.which("iverilog") and shutil.which("vvp"))
    if not DUT.is_file() or not TB.is_file() or not available:
        reason = ("RTL/TB 파일 없음" if not DUT.is_file() or not TB.is_file()
                  else "iverilog 또는 vvp 미설치")
        result["reason"] = reason
    else:
        version_code, version_text = execute(["iverilog", "-V"])
        result["simulator_version"] = version_text.splitlines()[0] if version_text else ""
        code, log = execute([
            "iverilog", "-g2012", "-s", "tb_uart_regression",
            "-o", "sim", str(DUT), str(TB)
        ])
        (BUILD / "compile.log").write_text(log, encoding="utf-8")
        if code != 0:
            result["status"] = "FAIL"
            result["reason"] = "컴파일 실패"
        else:
            for seed in seeds:
                code, log = execute(["vvp", "sim", f"+SEED={seed}"])
                (BUILD / f"seed_{seed}.log").write_text(log, encoding="utf-8")
                match = re.search(
                    rf"^PASS CH24 seed={seed} checks=32 accepted=([0-9]+)$",
                    log, re.MULTILINE
                )
                coverage = re.search(
                    rf"^COVERAGE seed={seed} idle=([0-9]+) stall=([0-9]+) "
                    rf"accept=([0-9]+) ready_idle=([0-9]+)$", log, re.MULTILINE
                )
                ok = (code == 0 and match is not None and coverage is not None
                      and all(int(v) > 0 for v in coverage.groups())
                      and sum(map(int, coverage.groups())) == 32)
                result["cases"].append({
                    "name": f"seed_{seed}", "status": "PASS" if ok else "FAIL",
                    "exit_code": code,
                    "accepted": int(match.group(1)) if match else None,
                    "coverage": list(map(int, coverage.groups())) if coverage else None,
                })
            code, log = execute(["vvp", "sim", "+SEED=1", "+INJECT_FAULT"])
            (BUILD / "negative.log").write_text(log, encoding="utf-8")
            detected = code != 0 and "DETECTED_INJECTED_FAULT case=9" in log
            result["cases"].append({
                "name": "negative_injection",
                "status": "PASS" if detected else "FAIL",
                "exit_code": code,
                "expected": "비정상 종료 및 지정된 오류 마커",
            })
            result["status"] = ("PASS" if all(
                item["status"] == "PASS" for item in result["cases"]
            ) else "FAIL")

    (BUILD / "report.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    lines = [
        "# 제24장 회귀 검증 보고서", "",
        f"- 실행 UTC: {result['timestamp_utc']}",
        f"- 상태: **{result['status']}**",
        f"- DUT Blob SHA: \`{EXPECTED_BLOB}\`",
        f"- 시뮬레이터: {result['simulator']}",
        f"- 버전: {result.get('simulator_version', '미확인')}",
        f"- 사유: {result.get('reason', '없음')}", "",
        "| 시험 | 상태 | 종료 코드 |",
        "|---|---|---|",
    ]
    for item in result["cases"]:
        lines.append(f"| {item['name']} | {item['status']} | {item['exit_code']} |")
    (BUILD / "report.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"CH24 REGRESSION {result['status']}: {BUILD / 'report.json'}")
    return {"PASS": 0, "FAIL": 1, "NOT_RUN": 2}[result["status"]]


if __name__ == "__main__":
    sys.exit(main())
