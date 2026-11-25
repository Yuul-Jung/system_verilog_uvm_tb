#!/usr/bin/env python3
"""Chrome에서 24장 × 6폭, SVG 경계·글자 충돌·탐색·클립보드를 검사한다.

사용: PYTHONPATH=.tools/browser-python python3 scripts/check_browser.py
Playwright와 설치된 google-chrome을 사용하며 결과는 .build/visual_v59에 저장한다.
"""

import functools
import hashlib
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import re
import threading

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / ".build/visual_v59"
WIDTHS = (1920, 1366, 1024, 768, 390, 320)
MEASURE = r"""() => {
  const box = e => {const r=e.getBBox(); return {x:r.x,y:r.y,w:r.width,h:r.height};};
  const overlap=(a,b)=>Math.min(a.x+a.w,b.x+b.w)-Math.max(a.x,b.x)>1 &&
    Math.min(a.y+a.h,b.y+b.h)-Math.max(a.y,b.y)>1;
  return {
    overflow: document.documentElement.scrollWidth > innerWidth + 1,
    headerTextClipped: [...document.querySelectorAll('.hero h1,.hero p,.hero .chip')]
      .filter(e=>e.scrollWidth>e.clientWidth+2).map(e=>e.textContent),
    contentOverflow: [...document.querySelectorAll('main table,main pre,main svg')].filter(e=>{
      let p=e.parentElement;
      while(p && p!==document.body) {
        if(['auto','scroll'].includes(getComputedStyle(p).overflowX)) return false;
        p=p.parentElement;
      }
      return e.getBoundingClientRect().right > innerWidth+1;
    }).map(e=>e.tagName),
    diagrams: [...document.querySelectorAll('main svg')].map((s,i)=>{
      const v=s.viewBox.baseVal;
      const text=[...s.querySelectorAll('text')].map(e=>({text:e.textContent.trim(),...box(e)}));
      const outside=text.filter(t=>t.x<v.x-1||t.y<v.y-1||t.x+t.w>v.x+v.width+1||t.y+t.h>v.y+v.height+1);
      const collisions=[];
      text.forEach((t,a)=>text.slice(a+1).forEach(u=>{if(overlap(t,u))collisions.push([t.text,u.text]);}));
      return {index:i+1, label:s.getAttribute('aria-label')||s.querySelector('title')?.textContent,
        viewBox:s.getAttribute('viewBox'),text,outside,collisions};
    })
  };
}"""


class QuietHandler(SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    server = ThreadingHTTPServer(("127.0.0.1", 0), functools.partial(QuietHandler, directory=str(ROOT)))
    threading.Thread(target=server.serve_forever, daemon=True).start()
    course = json.loads((ROOT / "course.json").read_text())
    rows = []
    with sync_playwright() as p:
        browser = p.chromium.launch(executable_path="/usr/bin/google-chrome", headless=True,
                                    args=["--no-sandbox"])
        context = browser.new_context(permissions=["clipboard-read", "clipboard-write"],
                                      reduced_motion="reduce")
        page = context.new_page()
        for c in course["chapters"]:
            file = f"{c['slug']}_{c['version']}.html"
            for width in WIDTHS:
                page.set_viewport_size({"width": width, "height": 1080 if width >= 768 else 844})
                response = page.goto(f"http://127.0.0.1:{server.server_port}/{file}")
                page.wait_for_selector(".course-ch-link")
                page.evaluate("document.fonts.ready")
                metrics = page.evaluate(MEASURE)
                metrics.update(chapter=c["number"], width=width, http=response.status,
                               nav=page.locator('.course-ch-link').count() == 4,
                               sections=page.locator('.toc-sections a').count() == page.locator('main section').count())
                if width <= 768:
                    toggle = page.locator('#mobile-menu')
                    toggle.focus()
                    page.keyboard.press('Enter')
                    opened = toggle.get_attribute('aria-expanded') == 'true'
                    page.keyboard.press('Escape')
                    closed = toggle.get_attribute('aria-expanded') == 'false'
                    metrics['keyboard_menu'] = opened and closed
                if width == 1920:
                    source = page.locator('.codeblock pre').first.text_content()
                    page.locator('.codebar button').first.click()
                    page.wait_for_function("document.querySelector('.codebar button').textContent === '복사 완료'")
                    metrics['clipboard'] = page.evaluate('navigator.clipboard.readText()') == source
                    for i, svg in enumerate(page.locator('main svg').all(), 1):
                        # 스크롤 컨테이너에 가려진 오른쪽 영역도 그림 증거에 보존한다.
                        old = svg.evaluate("e=>{const p=e.parentElement;const s=p.getAttribute('style');p.style.width=Math.max(e.getBoundingClientRect().width,p.scrollWidth)+'px';p.style.overflow='visible';return s;}")
                        svg.screenshot(path=str(OUT / f"ch{c['number']:02d}-svg{i}.png"))
                        svg.evaluate("(e,s)=>s===null?e.parentElement.removeAttribute('style'):e.parentElement.setAttribute('style',s)", old)
                    page.locator('.toc-sections a').last.click()
                    metrics['section_link'] = page.evaluate('location.hash') == page.locator('.toc-sections a').last.get_attribute('href')
                    page.goto(f"http://127.0.0.1:{server.server_port}/{file}")
                    page.wait_for_selector('.course-ch-link')
                page.screenshot(path=str(OUT / f"ch{c['number']:02d}-{width}.png"))
                rows.append(metrics)
            print(f"CH{c['number']:02d} browser widths=6", flush=True)
        redirects = []
        latest = {f"{c['slug']}_{c['version']}.html" for c in course['chapters']}
        for old in sorted(ROOT.glob('ch[0-9][0-9]_*.html')):
            if old.name in latest:
                continue
            target = re.search(r'<link rel="canonical" href="([^"]+)"', old.read_text())
            if not target:
                raise AssertionError(f"missing redirect: {old.name}")
            page.goto(f"http://127.0.0.1:{server.server_port}/{old.name}#s01")
            page.wait_for_url(f"**/{target[1]}#s01")
            redirects.append(dict(old=old.name, target=target[1], hash_preserved=True))
        browser.close()
    server.shutdown()
    (OUT / "measurements.json").write_text(json.dumps(rows, ensure_ascii=False, indent=2) + "\n")
    (OUT / "redirects.json").write_text(json.dumps(redirects, ensure_ascii=False, indent=2) + "\n")
    bad = [r for r in rows if r['overflow'] or r['contentOverflow'] or r['headerTextClipped'] or not r['nav'] or not r['sections']
           or r.get('keyboard_menu') is False or r.get('clipboard') is False
           or any(d['outside'] or d['collisions'] for d in r['diagrams'])]
    print(f"browser measurements={len(rows)} flagged={len(bad)}")
    return 1 if bad else 0


if __name__ == '__main__':
    raise SystemExit(main())
