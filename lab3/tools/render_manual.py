"""Render the Lab3 Markdown manual without modifying its source."""

import argparse
from dataclasses import dataclass, field
from hashlib import sha256
from html import escape
from html.parser import HTMLParser
from pathlib import Path
import re
import subprocess
import sys

from pypdf import PdfReader
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    KeepTogether, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle, XPreformatted,
)


@dataclass
class Node:
    tag: str
    children: list = field(default_factory=list)
    attrs: dict = field(default_factory=dict)


class DocumentParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.root = Node("root")
        self.stack = [self.root]

    def handle_starttag(self, tag, attrs):
        if tag not in {
            "h1", "h2", "h3", "p", "strong", "em", "code", "pre", "a",
            "ul", "ol", "li", "table", "thead", "tbody", "tr", "th", "td", "br",
        }:
            raise ValueError(f"Unsupported Markdown HTML element: {tag}")
        node = Node(tag, attrs=dict(attrs))
        self.stack[-1].children.append(node)
        if tag != "br":
            self.stack.append(node)

    def handle_endtag(self, tag):
        if self.stack[-1].tag != tag:
            raise ValueError(f"Unexpected closing tag: {tag}")
        self.stack.pop()

    def handle_data(self, data):
        self.stack[-1].children.append(data)


def plain(node):
    if isinstance(node, str):
        return node
    return "".join(plain(child) for child in node.children)


def inline(node):
    if isinstance(node, str):
        return escape(node)
    content = "".join(inline(child) for child in node.children)
    if node.tag == "strong":
        return f"<b>{content}</b>"
    if node.tag == "em":
        return f"<i>{content}</i>"
    if node.tag == "br":
        return "<br/>"
    if node.tag == "code":
        return f'<font backColor="#f1f1f1">{content}</font>'
    return content


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path,
                        default=Path(__file__).resolve().parents[1] / "resource/process.md")
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--markdown-python", default=sys.executable)
    parser.add_argument("--font", default="/System/Library/Fonts/Supplemental/Songti.ttc")
    args = parser.parse_args()
    if args.output.exists():
        raise FileExistsError(f"Refusing to overwrite: {args.output}")
    original = args.source.read_bytes()
    result = subprocess.run(
        [args.markdown_python, "-c",
         "import markdown,sys; print(markdown.markdown(sys.stdin.read(), "
         "extensions=['tables','fenced_code','sane_lists']))"],
        input=original.decode("utf-8"), text=True, capture_output=True, check=True,
    )
    document_parser = DocumentParser()
    document_parser.feed(result.stdout)
    document_parser.close()
    if len(document_parser.stack) != 1:
        raise ValueError("Unclosed HTML elements")
    pdfmetrics.registerFont(TTFont("Songti", args.font, subfontIndex=6))
    pdfmetrics.registerFont(TTFont("SongtiBold", args.font, subfontIndex=1))
    pdfmetrics.registerFontFamily("Songti", normal="Songti", bold="SongtiBold",
                                 italic="Songti", boldItalic="SongtiBold")
    body = ParagraphStyle(
        "body", fontName="Songti", fontSize=10.2, leading=15.2,
        wordWrap="CJK", spaceAfter=6, allowWidows=0, allowOrphans=0,
    )
    styles = {
        "p": body,
        "h1": ParagraphStyle("h1", parent=body, fontName="SongtiBold",
                             fontSize=18, leading=26, spaceAfter=12, keepWithNext=True),
        "h2": ParagraphStyle("h2", parent=body, fontName="SongtiBold",
                             fontSize=13, leading=20, spaceBefore=12,
                             spaceAfter=8, keepWithNext=True),
        "h3": ParagraphStyle("h3", parent=body, fontName="SongtiBold",
                             fontSize=11, leading=17, spaceBefore=6,
                             spaceAfter=6, keepWithNext=True),
    }
    cell_style = ParagraphStyle("cell", parent=body, fontSize=9.2, leading=13,
                               spaceAfter=0)
    header_style = ParagraphStyle("header", parent=cell_style, fontName="SongtiBold")
    code_style = ParagraphStyle(
        "code", parent=body, fontSize=9, leading=13, leftIndent=8,
        rightIndent=8, borderPadding=6, backColor=colors.HexColor("#f3f3f3"),
    )
    story = []
    checked_text = []
    available_width = A4[0] - 36 * mm

    def paragraph(node, style, prefix=""):
        checked_text.append(prefix + plain(node))
        result = Paragraph(prefix + inline(node), style)
        if plain(node).rstrip().endswith("："):
            result.keepWithNext = True
        return result

    def render(node):
        if isinstance(node, str):
            if node.strip():
                raise ValueError(f"Unexpected block text: {node}")
            return
        if node.tag in styles:
            story.append(paragraph(node, styles[node.tag]))
        elif node.tag in {"ul", "ol"}:
            items = [child for child in node.children if isinstance(child, Node)]
            for index, item in enumerate(items, int(node.attrs.get("start", "1"))):
                if item.tag != "li" or any(
                    isinstance(child, Node) and child.tag in {"ul", "ol", "p"}
                    for child in item.children
                ):
                    raise ValueError("Only tight, single-level lists are supported")
                prefix = f"{index}. " if node.tag == "ol" else "• "
                story.append(paragraph(item, body, prefix))
        elif node.tag == "pre":
            text = plain(node).rstrip("\n")
            checked_text.append(text)
            if any(pdfmetrics.stringWidth(line, "Songti", code_style.fontSize)
                   > available_width - 16 for line in text.splitlines()):
                raise ValueError("Code line too wide; adjust layout before rendering")
            block = [XPreformatted(escape(text), code_style)]
            if story and isinstance(story[-1], Paragraph) and story[-1].getKeepWithNext():
                label = story.pop()
                label.keepWithNext = False
                block.insert(0, label)
            story.extend([KeepTogether(block), Spacer(1, 8)])
        elif node.tag == "table":
            rows = []
            for group in node.children:
                if not isinstance(group, Node):
                    continue
                for row in group.children:
                    if not isinstance(row, Node):
                        continue
                    rows.append([
                        paragraph(cell, header_style if cell.tag == "th" else cell_style)
                        for cell in row.children if isinstance(cell, Node)
                    ])
            table = Table(rows, colWidths=[available_width / len(rows[0])] * len(rows[0]),
                          repeatRows=1, hAlign="LEFT")
            table.setStyle(TableStyle([
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#eeeeee")),
                ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#bbbbbb")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]))
            story.extend([table, Spacer(1, 9)])
        else:
            raise ValueError(f"Unsupported block: {node.tag}")

    for node in document_parser.root.children:
        render(node)
    for character in set("".join(checked_text)):
        if not character.isspace() and ord(character) not in pdfmetrics.getFont("Songti").face.charToGlyph:
            raise ValueError(f"Missing Songti glyph: {character!r}")

    def footer(canvas, document):
        canvas.saveState()
        canvas.setStrokeColor(colors.HexColor("#cccccc"))
        canvas.line(18 * mm, 16 * mm, A4[0] - 18 * mm, 16 * mm)
        canvas.setFont("Songti", 8)
        canvas.drawString(18 * mm, 11 * mm, "Lab3 · EGO1 · 实验操作手册（非实验报告）")
        canvas.drawRightString(A4[0] - 18 * mm, 11 * mm, str(document.page))
        canvas.restoreState()

    args.output.parent.mkdir(parents=True, exist_ok=True)
    document = SimpleDocTemplate(
        str(args.output), pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm,
        topMargin=17 * mm, bottomMargin=22 * mm,
        title="实验 3 操作手册：计数器流水灯（EGO1）", author="COMP2053",
    )
    document.build(story, onFirstPage=footer, onLaterPages=footer)
    if args.source.read_bytes() != original:
        raise AssertionError("Markdown source changed during rendering")
    reader = PdfReader(args.output)
    extracted = re.sub(r"\s+", "", "".join(page.extract_text() for page in reader.pages))
    missing = [text for text in checked_text if re.sub(r"\s+", "", text) not in extracted]
    if missing:
        raise AssertionError(f"PDF text verification failed: {missing[:3]}")
    print(f"PASS: {len(reader.pages)} pages, {len(checked_text)} text blocks, "
          f"Markdown unchanged, sha256={sha256(original).hexdigest()}")


if __name__ == "__main__":
    main()
