#!/usr/bin/env python3
"""발행 링크·절·SVG별 이름·실제 주 TB를 독립적으로 대조한다."""

from __future__ import annotations

import argparse
import json
import re
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input", "link",
        "meta", "param", "source", "track", "wbr", "path", "rect", "line", "polyline"}


class Element:
    def __init__(self, tag, attrs=()):
        self.tag = tag
        self.attrs = dict(attrs)
        self.children = []
        self.text = ""

    def find(self, tag):
        return [child for node in self.children
                for child in ([node] if node.tag == tag else []) + node.find(tag)]


class CoursePageParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = Element("document")
        self.stack = [self.root]

    def handle_starttag(self, tag, attrs):
        node = Element(tag, attrs)
        self.stack[-1].children.append(node)
        if tag not in VOID:
            self.stack.append(node)

    def handle_startendtag(self, tag, attrs):
        self.handle_starttag(tag, attrs)
        if self.stack[-1].tag == tag and tag not in VOID:
            self.stack.pop()

    def handle_endtag(self, tag):
        for index in range(len(self.stack) - 1, 0, -1):
            if self.stack[index].tag == tag:
                del self.stack[index:]
                break

    def handle_data(self, data):
        for node in self.stack:
            node.text += data


def parse(text):
    parser = CoursePageParser()
    parser.feed(text)
    return parser.root


def normalize(text):
    return text.replace("\r\n", "\n").strip()


def validate(root):
    errors = []
    course = json.loads((root / "course.json").read_text())
    chapters = course["chapters"]
    if len(chapters) != 24 or [c["number"] for c in chapters] != list(range(1, 25)):
        errors.append("course.json: expected chapters 1..24")
    if [c["id"] for c in chapters] != [f"ch{i:02d}" for i in range(1, 25)]:
        errors.append("course.json: invalid or duplicate chapter IDs")
    readme = (root / "README.md").read_text()
    readme = re.sub(r"<!--.*?-->|```.*?```", "", readme, flags=re.S)
    readme_links = re.findall(r'\]\(([^)\s]+)\)', readme)
    index_links = [e.attrs.get("href") for e in parse((root / "index.html").read_text()).find("a")]
    script = (root / "assets/site.js").read_text()
    # (변경) 세 문서를 합치지 않고 각각 실제 링크/스냅샷 필드를 검사한다.
    fallback = re.search(r'^\s*const fallback\s*=\s*(\{.*?\});', script, re.S | re.M)
    fallback_files = []
    if fallback:
        try:
            fallback_files = [c["file"] for c in json.loads(fallback[1])["chapters"]]
        except (ValueError, KeyError):
            pass
    for c in chapters:
        page_name = f"{c['slug']}_{c['version']}.html"
        for name, links in (("README", readme_links), ("INDEX", index_links),
                            ("site.js fallback", fallback_files)):
            if page_name not in links:
                errors.append(f"{c['id']}: missing actual link in {name}")
        path = root / page_name
        source = root / c["source"]
        if not path.is_file() or not source.is_file():
            errors.append(f"{c['id']}: missing HTML/source")
            continue
        document = parse(path.read_text())
        mains = document.find("main")
        if len(mains) != 1 or mains[0].attrs.get("id") != "main-content":
            errors.append(f"{c['id']}: expected one main#main-content")
            continue
        sections = mains[0].find("section")
        if not sections or [s.attrs.get("id") for s in sections] != [
                f"s{i:02d}" for i in range(len(sections))]:
            errors.append(f"{c['id']}: missing/duplicate/noncontiguous sections")
        for i, section in enumerate(sections):
            headings = [e for e in section.children if e.tag == "h2"]
            if len(headings) != 1 or not re.fullmatch(
                    rf"{i:02d}\s*\S.*", headings[0].text.strip(), re.S):
                errors.append(f"{c['id']}: section {i} missing numbered title")
        svgs = mains[0].find("svg")
        if not svgs:
            errors.append(f"{c['id']}: missing SVG")
        for i, svg in enumerate(svgs):
            titles = [e for e in svg.children if e.tag == "title" and e.text.strip()]
            labelled = svg.attrs.get("aria-labelledby", "").split()
            named_ids = {e.attrs.get("id") for tag in ("title", "text", "desc")
                         for e in svg.find(tag) if e.text.strip()}
            name_ok = (svg.attrs.get("aria-label", "").strip() or titles or
                       (labelled and all(x in named_ids for x in labelled)))
            if svg.attrs.get("role") != "img" or not name_ok:
                errors.append(f"{c['id']}: SVG {i + 1} missing own role/name")
        blocks = [normalize(e.text) for e in document.find("code")]
        if normalize(source.read_text()) not in blocks:
            errors.append(f"{c['id']}: primary source differs from HTML code")
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    args = parser.parse_args()
    try:
        errors = validate(args.root)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        errors = [str(exc)]
    for error in errors:
        print(f"FAIL: {error}")
    if errors:
        return 1
    print("PASS course validation: 24 chapters; per-file links, sections, SVG names, TB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
