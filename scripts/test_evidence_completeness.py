#!/usr/bin/env python3
"""실제 v59 증거 복사본과 변형본을 CLI 전체 실행으로 승인/거절한다."""

import copy
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import collect_evidence

ROOT = Path(__file__).resolve().parent.parent


class EvidenceCompletenessTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.bundle = Path(self.temp.name) / "evidence"
        shutil.copytree(ROOT / "docs/evidence/v59", self.bundle)
        self.original = json.loads((self.bundle / "manifest.json").read_text())
        # 검사기 개정 중에도 fixture의 보조 도구 해시는 현재 검사할 파일을 특정한다.
        audit_path = self.bundle / "audit_sources.json"
        audit = json.loads(audit_path.read_text())
        audit["files_sha256"] = {name: hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
                                for name in audit["files_sha256"]}
        audit_path.write_text(json.dumps(audit))
        self.refresh_sums()

    def refresh_sums(self):
        # (추가) 변형본은 manifest와 함께 공개 체크섬도 다시 계산한 공격자를 가정한다.
        sums = self.bundle / "SHA256SUMS"
        lines = []
        for line in sums.read_text().splitlines():
            _, _, name = line.partition("  ")
            if not (self.bundle / name).is_file():
                lines.append(line)
                continue
            digest = hashlib.sha256((self.bundle / name).read_bytes()).hexdigest()
            lines.append(f"{digest}  {name}")
        sums.write_text("\n".join(lines) + "\n")

    def verify(self, manifest, expected, message, refresh=True):
        (self.bundle / "manifest.json").write_text(json.dumps(manifest))
        if refresh:
            self.refresh_sums()
        result = subprocess.run([sys.executable, str(ROOT / "scripts/collect_evidence.py"),
                                 "--verify", "--output", str(self.bundle)],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
        self.assertIn(message, result.stdout)
        self.assertNotIn("Traceback", result.stderr)

    def rewrite_log(self, record, text):
        path = self.bundle / record["public_path"]
        path.write_text(text)
        # 해시를 맞춰도 내용·완전성 검사가 거절하는지 확인한다.
        record["public_sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
        record["bytes"] = path.stat().st_size

    def test_complete_real_evidence(self):
        self.verify(self.original, 0, "PASS evidence: 24 chapters, 12 negative cases")

    def test_order_and_optional_legacy_do_not_change_completeness(self):
        data = copy.deepcopy(self.original)
        data["chapters"].reverse()
        for chapter in data["chapters"]:
            chapter.pop("legacy_logs")
        self.verify(data, 0, "PASS evidence:")

    def test_three_reported_counterexamples_against_old_and_fixed_cli(self):
        baseline = subprocess.check_output(
            ["git", "show", "6edf029:scripts/collect_evidence.py"], cwd=ROOT, text=True)
        old = Path(self.temp.name) / "old_collector.py"
        old.write_text(baseline)
        empty = {"chapters": [], "sources_sha256": {}}
        single = {"chapter": 1, "status": "FAIL", "exit_code": 1, "logs": [], "legacy_logs": []}
        cases = {"empty": empty, "failed_single": dict(empty, chapters=[single]),
                 "duplicate_24": dict(empty, chapters=[single] * 24)}
        bare = Path(self.temp.name) / "bare"
        bare.mkdir()
        for name, data in cases.items():
            (bare / "manifest.json").write_text(json.dumps(data))
            before = subprocess.run([sys.executable, str(old), "--verify", "--output", str(bare)],
                                    capture_output=True, text=True)
            self.assertEqual(before.returncode, 0)
            self.verify(data, 1, "chapters must contain 01..24 exactly once")
            print(f"FULL_EVIDENCE {name}: baseline=0 fixed=1")

    def test_missing_each_chapter(self):
        for number in range(1, 25):
            with self.subTest(chapter=number):
                data = copy.deepcopy(self.original)
                data["chapters"].pop(number - 1)
                self.verify(data, 1, "chapters must contain 01..24 exactly once")

    def test_duplicate_and_invalid_chapter_ids(self):
        for value in (1, 25, 0, "2", False):
            with self.subTest(value=value):
                data = copy.deepcopy(self.original)
                data["chapters"][1]["chapter"] = value
                self.verify(data, 1, "chapters must contain 01..24 exactly once")

    def test_each_chapter_status_and_exit_code(self):
        for number in range(1, 25):
            for field, value in (("status", "NOT_RUN"), ("status", "FAIL"), ("exit_code", 1)):
                with self.subTest(chapter=number, field=field, value=value):
                    data = copy.deepcopy(self.original)
                    data["chapters"][number - 1][field] = value
                    self.verify(data, 1, f"CH{number:02d}: invalid status/exit_code")
        for value in ("0", False, None):
            data = copy.deepcopy(self.original)
            data["chapters"][3]["exit_code"] = value
            self.verify(data, 1, "CH04: invalid status/exit_code")
        data = copy.deepcopy(self.original)
        data["chapters"][0]["status"] = "PASS"
        self.verify(data, 1, "CH01: invalid status/exit_code")

    def test_each_required_log_record(self):
        for chapter in self.original["chapters"]:
            number = chapter["chapter"]
            paths = [r["public_path"] for r in chapter["logs"]
                     if r["public_path"].startswith(f"runs/ch{number:02d}/")
                     and "/.css/" not in r["public_path"] and "/.js/" not in r["public_path"]]
            for path in paths:
                with self.subTest(chapter=number, log=path):
                    data = copy.deepcopy(self.original)
                    logs = data["chapters"][number - 1]["logs"]
                    logs[:] = [record for record in logs if record["public_path"] != path]
                    self.verify(data, 1, f"missing required log: {path}")

    def test_duplicate_log_record(self):
        data = copy.deepcopy(self.original)
        data["chapters"][0]["logs"].append(data["chapters"][0]["logs"][0])
        self.verify(data, 1, "CH01: duplicate log path")

    def test_missing_file_and_hash_tampering(self):
        path = self.bundle / "runs/ch08/output.log"
        original = path.read_bytes()
        path.unlink()
        self.verify(self.original, 1, "missing log: runs/ch08/output.log")
        path.write_bytes(original + b"TAMPERED\n")
        self.verify(self.original, 1, "log SHA256: runs/ch08/output.log")

    def test_empty_and_wrong_normal_completion_with_valid_hash(self):
        for text in ("", "CH08 PASS: 3 cases checked\n"):
            data = copy.deepcopy(self.original)
            self.rewrite_log(data["chapters"][7]["logs"][0], text)
            self.verify(data, 1, "CH08: normal completion/diagnostic")

    def test_normal_fatal_and_nonzero_uvm_summary(self):
        record = self.original["chapters"][16]["logs"][0]
        original = (self.bundle / record["public_path"]).read_text()
        data = copy.deepcopy(self.original)
        self.rewrite_log(data["chapters"][16]["logs"][0], original + "Fatal: unrelated failure\n")
        self.verify(data, 1, "CH17: normal completion/diagnostic")
        for severity in ("ERROR", "FATAL"):
            data = copy.deepcopy(self.original)
            self.rewrite_log(data["chapters"][16]["logs"][0],
                             original.replace(f"UVM_{severity} :    0", f"UVM_{severity} :    1"))
            self.verify(data, 1, f"CH17: UVM_{severity} not zero")

    def test_missing_and_duplicate_negative_cases(self):
        for index in range(12):
            with self.subTest(case=index):
                data = copy.deepcopy(self.original)
                data["case_probes"].pop(index)
                self.verify(data, 1, "all 12 dedicated cases exactly once")
        for replacement in ([], None):
            data = copy.deepcopy(self.original)
            if replacement is None:
                data.pop("case_probes")
            else:
                data["case_probes"] = replacement
            self.verify(data, 1, "all 12 dedicated cases exactly once")
        data = copy.deepcopy(self.original)
        data["case_probes"][1] = copy.deepcopy(data["case_probes"][0])
        self.verify(data, 1, "all 12 dedicated cases exactly once")
        data = copy.deepcopy(self.original)
        data["case_probes"].append(copy.deepcopy(data["case_probes"][0]))
        self.verify(data, 1, "all 12 dedicated cases exactly once")

    def test_each_negative_status_exit_and_dedicated_diagnostic(self):
        for index, case in enumerate(self.original["case_probes"]):
            number, name = case["chapter"], case["name"]
            message = f"negative status/exit/diagnostic: CH{number:02d}/{name}"
            for field, value in (("status", "FAIL"), ("exit_code", 127), ("exit_code", False)):
                with self.subTest(case=(number, name), field=field):
                    data = copy.deepcopy(self.original)
                    data["case_probes"][index][field] = value
                    self.verify(data, 1, message)
            for text in ("", f"UVM_INFO {case['expected_marker']} only echoed, no Fatal\n"):
                data = copy.deepcopy(self.original)
                self.rewrite_log(data["case_probes"][index]["log"], text)
                self.verify(data, 1, message)

    def test_negative_does_not_trust_expected_marker_or_allow_normal_pass(self):
        index = 3
        data = copy.deepcopy(self.original)
        data["case_probes"][index]["expected_marker"] = "UNRELATED"
        self.rewrite_log(data["case_probes"][index]["log"], "UVM_FATAL [UNRELATED]\n")
        self.verify(data, 1, "negative status/exit/diagnostic: CH17/NO_VIF")
        data = copy.deepcopy(self.original)
        record = data["case_probes"][index]["log"]
        original = (ROOT / "docs/evidence/v59" / record["public_path"]).read_text()
        self.rewrite_log(record, original + "PASS CH17 checks=8\n")
        self.verify(data, 1, "negative status/exit/diagnostic: CH17/NO_VIF")
        for severity, before, after in (("ERROR", "0", "1"), ("FATAL", "1", "0")):
            data = copy.deepcopy(self.original)
            self.rewrite_log(data["case_probes"][index]["log"],
                             original.replace(f"UVM_{severity} :    {before}",
                                              f"UVM_{severity} :    {after}"))
            self.verify(data, 1, "negative status/exit/diagnostic: CH17/NO_VIF")

    def test_negative_exit_contract_and_paths(self):
        data = copy.deepcopy(self.original)
        for case in data["case_probes"]:
            if case["chapter"] not in (10, 24):
                case["exit_code"] = 1
        self.verify(data, 0, "PASS evidence:")
        for index in (0, 1, 11):
            data = copy.deepcopy(self.original)
            data["case_probes"][index]["exit_code"] = 0
            self.verify(data, 1, "negative status/exit/diagnostic")
        data = copy.deepcopy(self.original)
        data["case_probes"][1]["log"] = copy.deepcopy(data["case_probes"][0]["log"])
        self.verify(data, 1, "duplicate negative log path")

    def test_suite_negative_log_requires_diagnostic_too(self):
        data = copy.deepcopy(self.original)
        record = next(r for r in data["chapters"][9]["logs"]
                      if r["public_path"].endswith("fault_injection.log"))
        self.rewrite_log(record, "FATAL: wrong failure reason\n")
        self.verify(data, 1, "suite negative diagnostic: CH10/fault")

    def test_required_source_hashes(self):
        for empty in (True, False):
            data = copy.deepcopy(self.original)
            if empty:
                data["sources_sha256"] = {}
            else:
                data["sources_sha256"].pop("reference_rtl/pwm_core.v")
            self.verify(data, 1, "missing required sources_sha256 entries")
        data = copy.deepcopy(self.original)
        data["sources_sha256"]["reference_rtl/pwm_core.v"] = "0" * 64
        self.verify(data, 1, "source SHA256: reference_rtl/pwm_core.v")

    def test_required_sources_do_not_disappear_with_missing_files(self):
        root = Path(self.temp.name) / "empty_sources"
        root.mkdir()
        shutil.copy(ROOT / "course.json", root / "course.json")
        with patch.object(collect_evidence, "ROOT", root):
            paths = {p.relative_to(root).as_posix() for p in collect_evidence.required_sources()}
        self.assertEqual(paths, set(self.original["sources_sha256"]))
        self.assertEqual(len(paths), 67)

    def test_ch24_incomplete_report_with_valid_hash(self):
        record = next(r for r in self.original["chapters"][23]["logs"]
                      if r["public_path"].endswith("report.json"))
        original = json.loads((self.bundle / record["public_path"]).read_text())
        for change in ("status", "case", "seeds"):
            data = copy.deepcopy(self.original)
            report = copy.deepcopy(original)
            if change == "status":
                report["status"] = "FAIL"
            elif change == "case":
                report["cases"].pop()
            else:
                report["seeds"] = [1]
            target = next(r for r in data["chapters"][23]["logs"]
                          if r["public_path"].endswith("report.json"))
            self.rewrite_log(target, json.dumps(report))
            self.verify(data, 1, "CH24: incomplete/failed report.json")

    def test_sha256sums_mismatch(self):
        # (추가) 공개 체크섬 목록과 다른 바이트는 manifest가 맞아도 거절한다.
        self.verify(self.original, 0, "PASS evidence:")
        data = copy.deepcopy(self.original)
        data["chapters"].reverse()
        self.verify(data, 1, "SHA256SUMS: manifest.json", refresh=False)

    def test_malformed_evidence_fails_cleanly(self):
        self.verify({}, 1, "malformed/incomplete evidence")
        data = copy.deepcopy(self.original)
        data["chapters"][0]["logs"][0]["public_path"] = "../outside.txt"
        self.verify(data, 1, "file path escapes evidence/source root")


if __name__ == "__main__":
    unittest.main(verbosity=2)
