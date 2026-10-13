#!/usr/bin/env python3
"""Download the digital logic course website as an offline Markdown collection."""

import argparse
import base64
from collections import deque
from datetime import datetime, timezone
import hashlib
import html
import json
import mimetypes
import os
from pathlib import Path
import re
import sys
import time
from urllib.parse import quote, unquote, unquote_to_bytes, urldefrag, urljoin, urlsplit, urlunsplit
from urllib.robotparser import RobotFileParser
import xml.etree.ElementTree as ET

from bs4 import BeautifulSoup
from markdownify import MarkdownConverter
import requests


DEFAULT_URL = "https://diglogic.p.cs-lab.top/"
USER_AGENT = "COMP2053-OfflineMirror/1.0"


def normalize_url(url):
    parts = urlsplit(urldefrag(url)[0])
    path = re.sub(r"/index\.html?$", "/", parts.path or "/")
    return urlunsplit((parts.scheme.lower(), parts.netloc.lower(), path, parts.query, ""))


def safe_name(name):
    name = re.sub(r'[^\w.\-]', "_", unquote(name)).strip(".")
    return name[:120] or "_"


def page_path(url):
    parts = urlsplit(url)
    segments = [safe_name(part) for part in parts.path.split("/") if part]
    if parts.path.endswith("/") or not Path(parts.path).suffix:
        segments.append("index.md")
    else:
        segments[-1] += ".md"
    path = Path("pages", *segments)
    if parts.query:
        digest = hashlib.sha256(parts.query.encode()).hexdigest()[:12]
        path = path.with_name(f"{path.stem}-{digest}.md")
    return path


def relative_link(target, current):
    return quote(Path(os.path.relpath(target, current.parent)).as_posix(), safe="/-._~")


class CourseMarkdownConverter(MarkdownConverter):
    def convert_a(self, element, text, parent_tags):
        if element.get("id") and not element.get("href"):
            return f'<a id="{html.escape(element["id"], quote=True)}"></a>'
        return super().convert_a(element, text, parent_tags)

    def convert_pre(self, element, text, parent_tags):
        code = element.get_text().strip("\n")
        classes = element.get("class", []) + (
            element.code.get("class", []) if element.code else []
        )
        language = next(
            (name.removeprefix("language-") for name in classes if name.startswith("language-")),
            "",
        )
        longest = max((len(match) for match in re.findall(r"`+", code)), default=0)
        fence = "`" * max(3, longest + 1)
        return f"\n\n{fence}{language}\n{code}\n{fence}\n\n"

    def convert_div(self, element, text, parent_tags):
        if "arithmatex" in element.get("class", []):
            return f"\n\n{element.get_text()}\n\n"
        if "admonition" in element.get("class", []):
            return "\n\n" + "\n".join("> " + line for line in text.strip().splitlines()) + "\n\n"
        return super().convert_div(element, text, parent_tags)

    def convert_span(self, element, text, parent_tags):
        if "arithmatex" in element.get("class", []):
            return element.get_text()
        return text

    def convert_table(self, element, text, parent_tags):
        if element.select("[rowspan], [colspan]"):
            return f"\n\n{element}\n\n"
        return super().convert_table(element, text, parent_tags)

    def convert_video(self, element, text, parent_tags):
        return f"\n\n{element}\n\n"

    def convert_iframe(self, element, text, parent_tags):
        return f"\n\n[嵌入内容]({element.get('src', '')})\n\n"

    convert_embed = convert_iframe
    convert_audio = convert_video
    convert_object = convert_video
    convert_svg = convert_video


class Mirror:
    def __init__(self, base_url, output, delay, timeout, retries):
        self.base_url = normalize_url(base_url)
        self.output = output
        self.delay = delay
        self.timeout = timeout
        self.retries = retries
        self.session = requests.Session()
        self.session.headers["User-Agent"] = USER_AGENT
        self.robots = None
        self.pages = {}
        self.assets = {}
        self.aliases = {}
        self.failures = {}
        self.warnings = []
        self.last_request = 0.0
        self.converter = CourseMarkdownConverter(
            heading_style="ATX",
            bullets="-",
            keep_inline_images_in=["td", "th", "h1", "h2", "h3", "a"],
        )

    def internal(self, url):
        return urlsplit(url)[:2] == urlsplit(self.base_url)[:2]

    def page_candidate(self, url):
        return self.internal(url) and Path(urlsplit(url).path).suffix.lower() in {
            "", ".html", ".htm",
        }

    def fail(self, url, message):
        self.failures[url] = str(message)
        print(f"  失败：{url}: {message}", file=sys.stderr)

    def fetch(self, url, optional=False):
        if self.robots and self.internal(url) and not self.robots.can_fetch(USER_AGENT, url):
            self.fail(url, "robots.txt 禁止抓取")
            return None
        for attempt in range(self.retries + 1):
            time.sleep(max(0, self.delay - (time.monotonic() - self.last_request)))
            self.last_request = time.monotonic()
            try:
                response = self.session.get(url, timeout=self.timeout)
                if optional and response.status_code in {404, 410}:
                    return None
                response.raise_for_status()
                return response
            except requests.RequestException as error:
                status = error.response.status_code if error.response is not None else None
                if attempt == self.retries or (status and 400 <= status < 500 and status != 429):
                    self.fail(url, error)
                    return None
                time.sleep(2 ** attempt)
        return None

    def discover(self):
        urls = [self.base_url]
        robots_url = urljoin(self.base_url, "/robots.txt")
        robots = self.fetch(robots_url, optional=True)
        sitemaps = [urljoin(self.base_url, "sitemap.xml")]
        if robots is not None:
            self.robots = RobotFileParser(robots_url)
            self.robots.parse(robots.text.splitlines())
            sitemaps.extend(self.robots.site_maps() or [])
            self.delay = max(self.delay, self.robots.crawl_delay(USER_AGENT) or 0)
        visited = set()
        while sitemaps:
            sitemap = sitemaps.pop()
            if sitemap in visited or not self.internal(sitemap):
                continue
            visited.add(sitemap)
            response = self.fetch(sitemap, optional=True)
            if response is None:
                continue
            try:
                root = ET.fromstring(response.content)
                locations = [node.text.strip() for node in root.iter()
                             if node.tag.split("}")[-1] == "loc" and node.text]
                if root.tag.split("}")[-1] == "sitemapindex":
                    sitemaps.extend(locations)
                else:
                    urls.extend(locations)
            except ET.ParseError as error:
                self.fail(sitemap, error)
        search_url = urljoin(self.base_url, "search/search_index.json")
        response = self.fetch(search_url, optional=True)
        if response is not None:
            try:
                urls.extend(urljoin(self.base_url, entry["location"])
                            for entry in response.json()["docs"])
            except (ValueError, KeyError, TypeError) as error:
                self.fail(search_url, error)
        return urls

    def save_asset(self, url, content, content_type):
        parts = urlsplit(url)
        name = safe_name(Path(parts.path).name) if parts.scheme != "data" else "embedded"
        if not Path(name).suffix:
            name += mimetypes.guess_extension(content_type.split(";")[0]) or ".bin"
        digest = hashlib.sha256(url.encode()).hexdigest()[:16]
        path = Path("assets", safe_name(parts.netloc or "inline"), f"{digest}-{name}")
        destination = self.output / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(content)
        self.assets[url] = {
            "path": path.as_posix(),
            "bytes": len(content),
            "sha256": hashlib.sha256(content).hexdigest(),
        }
        return path

    def download_asset(self, url):
        url = urldefrag(url)[0]
        if url in self.assets:
            return Path(self.assets[url]["path"])
        if url in self.failures:
            return None
        if url.startswith("data:"):
            try:
                header, payload = url.split(",", 1)
                content = unquote_to_bytes(payload)
                if ";base64" in header:
                    content = base64.b64decode(content, validate=True)
                return self.save_asset(url, content, header[5:].split(";")[0])
            except ValueError as error:
                self.fail(url[:100], error)
                return None
        if urlsplit(url).scheme not in {"http", "https"}:
            return None
        print(f"  资源：{url}", flush=True)
        response = self.fetch(url)
        if response is None:
            return None
        return self.save_asset(url, response.content, response.headers.get("Content-Type", ""))

    def crawl(self):
        queue = deque(self.discover())
        visited = set()
        while queue:
            url = normalize_url(queue.popleft())
            if url in visited or not self.page_candidate(url):
                continue
            visited.add(url)
            print(f"页面：{url}", flush=True)
            response = self.fetch(url)
            if response is None:
                continue
            final_url = normalize_url(response.url)
            if not self.internal(final_url):
                self.fail(url, f"页面重定向到站外：{final_url}")
                continue
            self.aliases[url] = final_url
            if final_url in self.pages:
                continue
            content_type = response.headers.get("Content-Type", "")
            if "html" not in content_type.lower():
                self.save_asset(url, response.content, content_type)
                continue
            document = BeautifulSoup(response.content, "html.parser")
            body = (document.select_one("article.md-content__inner")
                    or document.find("article") or document.find("main"))
            if body is None:
                self.fail(url, "找不到页面正文（article/main），未生成不完整 Markdown")
                continue
            heading = body.find("h1") or document.title
            title = heading.get_text(" ", strip=True) if heading else final_url
            path = page_path(final_url)
            if any(page["path"] == path for page in self.pages.values()):
                path = path.with_name(
                    f"{path.stem}-{hashlib.sha256(final_url.encode()).hexdigest()[:12]}.md"
                )
            raw_path = self.output / "html" / path.relative_to("pages").with_suffix(".html")
            raw_path.parent.mkdir(parents=True, exist_ok=True)
            raw_path.write_bytes(response.content)
            base = document.find("base", href=True)
            link_base = urljoin(final_url, base["href"]) if base else final_url
            self.pages[final_url] = {
                "path": path, "title": title, "body": body, "base": link_base,
            }
            queue.extend(urljoin(link_base, anchor["href"])
                         for anchor in document.select("a[href]"))

    def rewrite_link(self, value, page, embedded=False):
        absolute = urljoin(page["base"], value)
        url, fragment = urldefrag(absolute)
        canonical = normalize_url(url)
        target = self.pages.get(self.aliases.get(canonical, canonical))
        if not embedded and target:
            path = target["path"]
        elif embedded or (self.internal(url) and not self.page_candidate(url)) or url in self.assets:
            path = self.download_asset(url)
        else:
            path = None
        if path:
            return relative_link(path, page["path"]) + (
                "#" + quote(unquote(fragment), safe="-._~") if fragment else ""
            )
        return absolute

    def render(self):
        for url, page in self.pages.items():
            body = page["body"]
            for element in body.select("script, style, .headerlink, .md-content__button"):
                element.decompose()
            for element in body.select("[id]"):
                anchor = BeautifulSoup("", "html.parser").new_tag("a", id=element["id"])
                element.insert_before(anchor)
                del element["id"]
            for image in body.select("img"):
                if image.get("data-src"):
                    image["src"] = image["data-src"]
                if not image.get("src"):
                    self.fail(url, "正文图片缺少 src/data-src")
            for element in body.select("[src], [poster], object[data]"):
                for attribute in ("src", "poster", "data"):
                    if element.get(attribute):
                        element[attribute] = self.rewrite_link(
                            element[attribute], page,
                            embedded=element.name not in {"iframe", "embed"},
                        )
            for element in body.select("[srcset]"):
                candidates = []
                for candidate in element["srcset"].split(","):
                    fields = candidate.split()
                    if fields:
                        fields[0] = self.rewrite_link(fields[0], page, embedded=True)
                        candidates.append(" ".join(fields))
                element["srcset"] = ", ".join(candidates)
            for anchor in body.select("a[href]"):
                anchor["href"] = self.rewrite_link(anchor["href"], page)
            for frame in body.select("iframe[src], embed[src]"):
                if urlsplit(frame["src"]).scheme in {"http", "https"}:
                    self.warnings.append(f"{url} 包含嵌入页面，离线可能不可用：{frame['src']}")
            markdown = self.converter.convert(str(body)).strip()
            if not body.find("h1"):
                markdown = f"# {page['title']}\n\n{markdown}"
            destination = self.output / page["path"]
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_text(f"> 原文：{url}\n\n{markdown}\n", encoding="utf-8")

    def write_manifest(self):
        pages = {url: {"title": page["title"], "path": page["path"].as_posix()}
                 for url, page in self.pages.items()}
        manifest = {
            "source": self.base_url,
            "downloaded_at": datetime.now(timezone.utc).isoformat(),
            "pages": pages,
            "assets": self.assets,
            "failures": self.failures,
            "warnings": self.warnings,
        }
        self.output.mkdir(parents=True, exist_ok=True)
        (self.output / "manifest.json").write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
        )
        lines = [
            "# 数字逻辑实验指导 · 离线目录", "",
            f"来源：{self.base_url}", "",
            f"本次下载：{len(pages)} 个页面、{len(self.assets)} 个资源；"
            f"{len(self.failures)} 项失败。", "",
        ]
        lines.extend(f"- [{page['title'].replace('[', '').replace(']', '')}]"
                     f"({quote(page['path'], safe='/-._~')})" for page in pages.values())
        if self.failures or self.warnings:
            lines.extend(["", "## 下载问题", "",
                          "详见 `manifest.json` 中的 `failures` 和 `warnings`。"])
        (self.output / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    def run(self):
        try:
            self.crawl()
            self.render()
            self.write_manifest()
        finally:
            self.session.close()
        print(f"\n完成：{len(self.pages)} 个页面，{len(self.assets)} 个资源，"
              f"{len(self.failures)} 项失败。目录：{self.output}")
        return 1 if self.failures or not self.pages else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default=DEFAULT_URL, help="站点根地址")
    parser.add_argument("--output", type=Path, default=Path(__file__).resolve().parent / "mirror",
                        help="输出目录（默认：脚本旁的 mirror/）")
    parser.add_argument("--delay", type=float, default=0.2, help="请求间隔秒数（默认：0.2）")
    parser.add_argument("--timeout", type=float, default=30, help="单次请求超时秒数（默认：30）")
    parser.add_argument("--retries", type=int, default=2, help="失败重试次数（默认：2）")
    args = parser.parse_args()
    if urlsplit(args.url).scheme not in {"http", "https"} or not urlsplit(args.url).netloc:
        parser.error("--url 必须是有效的 HTTP(S) 地址")
    if args.delay < 0 or args.timeout <= 0 or args.retries < 0:
        parser.error("delay/retries 不能为负，timeout 必须大于 0")
    return Mirror(args.url.rstrip("/") + "/", args.output.resolve(),
                  args.delay, args.timeout, args.retries).run()


if __name__ == "__main__":
    sys.exit(main())
