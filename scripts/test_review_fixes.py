#!/usr/bin/env python3
"""V58-01/02/08: 전체 실행기와 검사기에 정상·부정 반례를 넣는다."""

import html
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

from collect_evidence import sanitize

ROOT = Path(__file__).resolve().parent.parent


class ReviewTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "scripts").mkdir()
        (self.root / "assets").mkdir()
        self.chapters = []
        for n in range(1, 25):
            chapter = f"ch{n:02d}"
            source = f"tb/{chapter}/tb.sv"
            path = self.root / source
            path.parent.mkdir(parents=True)
            path.write_text(f"module tb{n}; endmodule\n")
            self.chapters.append(dict(id=chapter, number=n, slug=chapter, version="v01",
                                      source=source))
            (self.root / f"{chapter}_v01.html").write_text(
                '<html><head><title>Document title</title></head><body>'
                '<main id="main-content"><section id="s00"><h2>00 개요</h2>'
                '<svg role="img"><title>Own title</title></svg>'
                f'<pre><code>{html.escape(path.read_text())}</code></pre>'
                '</section></main></body></html>')
            runner = (f"tb/{chapter}/run_{chapter}.sh" if n in (11, 12)
                      else f"scripts/run_{chapter}.sh")
            (self.root / runner).write_text(f"printf 'RUN {chapter}\\n'\n")
        (self.root / "course.json").write_text(json.dumps({"chapters": self.chapters}))
        names = [f"ch{n:02d}_v01.html" for n in range(1, 25)]
        (self.root / "README.md").write_text("\n".join(f"[ch]({x})" for x in names))
        (self.root / "index.html").write_text("".join(f'<a href="{x}">ch</a>' for x in names))
        (self.root / "assets/site.js").write_text("const fallback = " + json.dumps(
            {"chapters": [{"file": x} for x in names]}) + ";")
        shutil.copy(ROOT / "scripts/run_chapter.sh", self.root / "scripts/run_chapter.sh")
        (self.root / "scripts/setup_env.sh").write_text(":\n")

    def validate(self):
        return subprocess.run([sys.executable, str(ROOT / "scripts/validate_course.py"),
                               "--root", str(self.root)], capture_output=True, text=True)

    def mutate(self, name, before, after):
        path = self.root / name
        text = path.read_text()
        self.assertIn(before, text)
        path.write_text(text.replace(before, after))

    def test_normal(self):
        self.assertEqual(self.validate().returncode, 0)

    def test_original_full_validator_counterexamples(self):
        baseline = subprocess.check_output(
            ['git', 'show', '10d0ec0:scripts/validate_course.py'], cwd=ROOT, text=True)
        old = self.root / 'scripts/old_validator.py'
        old.write_text(baseline)
        for case in ('normal', 'no_sections', 'unnamed_svg', 'only_sitejs_latest'):
            originals = {p: p.read_text() for p in (self.root / 'ch01_v01.html',
                         self.root / 'README.md', self.root / 'index.html')}
            if case == 'no_sections':
                self.mutate('ch01_v01.html', '<section id="s00">', '<div>')
                self.mutate('ch01_v01.html', '</section>', '</div>')
            elif case == 'unnamed_svg':
                self.mutate('ch01_v01.html', '<title>Own title</title>', '')
            elif case == 'only_sitejs_latest':
                for name in ('README.md', 'index.html'):
                    self.mutate(name, 'ch01_v01.html', 'old.html')
            before = subprocess.run([sys.executable, str(old)], capture_output=True, text=True)
            after = self.validate()
            self.assertEqual(before.returncode, 0)
            self.assertEqual(after.returncode, 0 if case == 'normal' else 1)
            print(f'FULL_VALIDATOR {case}: baseline={before.returncode} fixed={after.returncode}')
            for path, text in originals.items():
                path.write_text(text)

    def test_missing_sections(self):
        self.mutate("ch01_v01.html", '<section id="s00">', '<div>')
        self.mutate("ch01_v01.html", '</section>', '</div>')
        self.assertNotEqual(self.validate().returncode, 0)

    def test_document_title_does_not_name_svg(self):
        self.mutate("ch01_v01.html", '<title>Own title</title>', '')
        self.assertNotEqual(self.validate().returncode, 0)

    def test_one_named_svg_does_not_name_another(self):
        self.mutate("ch01_v01.html", '</svg>', '</svg><svg role="img"></svg>')
        self.assertNotEqual(self.validate().returncode, 0)

    def test_missing_links_in_each_file(self):
        for name in ("README.md", "index.html", "assets/site.js"):
            with self.subTest(name=name):
                original = (self.root / name).read_text()
                (self.root / name).write_text(original.replace("ch01_v01.html", "old.html"))
                self.assertNotEqual(self.validate().returncode, 0)
                (self.root / name).write_text(original)

    def test_plain_index_filename_is_not_link(self):
        self.mutate("index.html", '<a href="ch01_v01.html">ch</a>', 'ch01_v01.html')
        self.assertNotEqual(self.validate().returncode, 0)

    def test_readme_commented_link_is_not_navigation(self):
        self.mutate("README.md", '[ch](ch01_v01.html)', '<!-- [ch](ch01_v01.html) -->')
        self.assertNotEqual(self.validate().returncode, 0)

    def test_duplicate_chapter_id(self):
        self.chapters[1]['id'] = 'ch01'
        (self.root / "course.json").write_text(json.dumps({'chapters': self.chapters}))
        self.assertNotEqual(self.validate().returncode, 0)

    def test_svg_label_must_exist_in_same_svg(self):
        self.mutate("ch01_v01.html", '<svg role="img"><title>Own title</title></svg>',
                    '<svg role="img" aria-labelledby="outside"></svg><p id="outside">Label</p>')
        self.assertNotEqual(self.validate().returncode, 0)

    def test_missing_or_duplicate_title_or_id(self):
        for before, after in (('<h2>00 개요</h2>', ''), ('<h2>00 개요</h2>', '<h2>00</h2>'),
                              ('id="s00"', 'id="s01"'),
                              ('</section>', '</section><section id="s00"><h2>00 복제</h2></section>')):
            with self.subTest(after=after):
                original = (self.root / "ch01_v01.html").read_text()
                self.mutate("ch01_v01.html", before, after)
                self.assertNotEqual(self.validate().returncode, 0)
                (self.root / "ch01_v01.html").write_text(original)

    def test_missing_svg_or_changed_tb(self):
        for before, after in (('<svg role="img"><title>Own title</title></svg>', ''),
                              ('module tb1;', 'module wrong;')):
            original = (self.root / "ch01_v01.html").read_text()
            self.mutate("ch01_v01.html", before, after)
            self.assertNotEqual(self.validate().returncode, 0)
            (self.root / "ch01_v01.html").write_text(original)

    def test_svg_own_names(self):
        for svg in ('<svg role="img" aria-label="Label"></svg>',
                    '<svg role="img" aria-labelledby="label"><title id="label">Label</title></svg>'):
            original = (self.root / "ch01_v01.html").read_text()
            self.mutate("ch01_v01.html", '<svg role="img"><title>Own title</title></svg>', svg)
            self.assertEqual(self.validate().returncode, 0)
            (self.root / "ch01_v01.html").write_text(original)

    def test_dispatch_all_24_paths(self):
        for n in range(1, 25):
            chapter = f"{n:02d}"
            result = subprocess.run(["bash", str(self.root / "scripts/run_chapter.sh"), chapter],
                                    capture_output=True, text=True, cwd="/tmp")
            self.assertEqual((result.returncode, result.stdout.strip()), (0, f"RUN ch{chapter}"))

    def test_dispatch_rejects_invalid_input(self):
        for chapter in ("00", "25", "1", "../11", "11;false", "", "$(false)"):
            result = subprocess.run(["bash", str(self.root / "scripts/run_chapter.sh"), chapter],
                                    capture_output=True, text=True)
            self.assertEqual(result.returncode, 2)

    def test_ch08_pass_marker_and_simulator_exit(self):
        shutil.copy(ROOT / "scripts/run_ch08.sh", self.root / "scripts/run_ch08.sh")
        (self.root / "reference_rtl").mkdir()
        (self.root / "reference_rtl/uart_echo_controller.v").write_text("module dut; endmodule")
        bindir = self.root / "bin"
        bindir.mkdir()
        # 컴파일러/실행 파일을 대역으로 두고 스크립트의 최종 판정만 시험한다.
        for name in ("verilator", "z3"):
            path = bindir / name
            path.write_text("#!/bin/bash\nexit 0\n")
            path.chmod(0o755)
        output = self.root / ".build/ch08/obj_dir"
        output.mkdir(parents=True)
        binary = output / "Vtb_uart_objects"
        env = dict(os.environ, PATH=f"{bindir}:{os.environ['PATH']}")
        for text, sim_exit, expected in (("CH08 PASS: 4 cases checked", 0, 0),
                                         ("", 0, 1), ("CH08 PASS: 3 cases checked", 0, 1),
                                         ("prefix CH08 PASS: 4 cases checked", 0, 1),
                                         ("CH08 PASS: 4 cases checked", 1, 1)):
            binary.write_text(f"#!/bin/bash\nprintf '%s\\n' '{text}'\nexit {sim_exit}\n")
            binary.chmod(0o755)
            result = subprocess.run(["bash", str(self.root / "scripts/run_ch08.sh")],
                                    env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, expected, result.stdout)

    def test_evidence_redaction(self):
        import getpass
        import socket
        user, host = getpass.getuser(), socket.gethostname()
        private = (f"/home/example/project a.person@example.com /srv/{user}/x "
                   f"{user}@{host} USER={user} host={host}")
        public = sanitize(private)
        for value in ("/home/", "a.person@example.com", f"/{user}/", f"{user}@",
                      f"USER={user}", host):
            self.assertNotIn(value, public)

    def test_evidence_redaction_keeps_common_words(self):
        # (추가) 계정명이 root여도 일반 문장의 단어는 훼손하지 않는다.
        from unittest.mock import patch
        with patch("getpass.getuser", return_value="root"):
            self.assertEqual(sanitize("file path escapes evidence/source root"),
                             "file path escapes evidence/source root")
            self.assertEqual(sanitize("/srv/root/x root@pc"), "/srv/[USER]/x [USER]@pc")

    def test_evidence_hash_rejects_tampered_log(self):
        source = ROOT / 'docs/evidence/v59'
        if not (source / 'manifest.json').is_file():
            self.skipTest('run collect_evidence.py first')
        bundle = self.root / 'evidence'
        shutil.copytree(source, bundle)
        command = [sys.executable, str(ROOT / 'scripts/collect_evidence.py'), '--verify',
                   '--output', str(bundle)]
        self.assertEqual(subprocess.run(command, capture_output=True).returncode, 0)
        log = bundle / 'runs/ch01/output.log'
        log.write_text(log.read_text() + 'TAMPERED\n')
        self.assertEqual(subprocess.run(command, capture_output=True).returncode, 1)


if __name__ == "__main__":
    unittest.main(verbosity=2)
