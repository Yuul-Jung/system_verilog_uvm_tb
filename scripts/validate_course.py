#!/usr/bin/env python3
"""Check the published course index against its source files."""

from __future__ import annotations

import json
import re
import sys
from html.parser import HTMLParser
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent


class CoursePageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.code_depth = 0
        self.code_buffer: list[str] = []
        self.code_blocks: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag == "code":
            self.code_depth += 1
            self.code_buffer = []

    def handle_endtag(self, tag: str) -> None:
        if tag == "code" and self.code_depth:
            self.code_blocks.append(normalize("".join(self.code_buffer)))
            self.code_depth -= 1

    def handle_data(self, data: str) -> None:
        if self.code_depth:
            self.code_buffer.append(data)


def normalize(text: str) -> str:
    return text.replace("\r\n", "\n").strip()


def fail(message: str, failures: list[str]) -> None:
    failures.append(message)
    print(f"FAIL: {message}", file=sys.stderr)


def main() -> int:
    failures: list[str] = []
    course = json.loads((ROOT / "course.json").read_text(encoding="utf-8"))
    chapters = course["chapters"]

    if len(chapters) != 24:
        fail(f"course.json contains {len(chapters)} chapters, expected 24", failures)

    if [chapter["number"] for chapter in chapters] != list(range(1, 25)):
        fail("chapter numbers are not the contiguous range 1..24", failures)

    navigation_text = "\n".join(
        (ROOT / name).read_text(encoding="utf-8")
        for name in ("README.md", "index.html", "assets/site.js")
    )

    for chapter in chapters:
        page_name = f"{chapter['slug']}_{chapter['version']}.html"
        page_path = ROOT / page_name
        source_path = ROOT / chapter["source"]

        if not page_path.is_file():
            fail(f"{chapter['id']}: missing latest page {page_name}", failures)
            continue
        if not source_path.is_file():
            fail(f"{chapter['id']}: missing source {chapter['source']}", failures)
            continue
        if page_name not in navigation_text:
            fail(f"{chapter['id']}: latest page absent from navigation", failures)

        page = page_path.read_text(encoding="utf-8")
        if "<main" not in page:
            fail(f"{chapter['id']}: main element is missing", failures)

        section_ids = [int(value) for value in re.findall(r'<section[^>]+id="s(\d\d)"', page)]
        if section_ids != list(range(len(section_ids))):
            fail(f"{chapter['id']}: section IDs are not contiguous: {section_ids}", failures)

        svg_tags = re.findall(r"<svg\b[^>]*>", page)
        for index, svg_tag in enumerate(svg_tags, start=1):
            if 'role="img"' not in svg_tag:
                fail(f"{chapter['id']}: SVG {index} lacks role=img", failures)
            has_label = 'aria-label="' in svg_tag or 'aria-labelledby="' in svg_tag
            if not has_label and "<title" not in page:
                fail(f"{chapter['id']}: SVG {index} lacks an accessible label", failures)

        parser = CoursePageParser()
        parser.feed(page)
        source = normalize(source_path.read_text(encoding="utf-8"))
        if source not in parser.code_blocks:
            fail(f"{chapter['id']}: primary source is not an exact HTML code block", failures)

    if failures:
        print(f"FAIL course validation: {len(failures)} issue(s)", file=sys.stderr)
        return 1

    print(f"PASS course validation: {len(chapters)} chapters, source and navigation aligned")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
