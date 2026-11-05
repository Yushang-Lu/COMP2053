"""Adapt the Lab2 report renderer for Lab4 without changing source material."""

import argparse
from hashlib import sha256
from html import escape
from io import BytesIO
from pathlib import Path
import re

from PIL import Image as PillowImage
from pypdf import PdfReader
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Image, PageBreak, Paragraph, SimpleDocTemplate, Spacer


def render(source, output):
    if output.exists():
        raise FileExistsError(f"Refusing to overwrite: {output}")
    original = source.read_bytes()
    font_path = "/System/Library/Fonts/Supplemental/Songti.ttc"
    pdfmetrics.registerFont(TTFont("Songti", font_path, subfontIndex=6))
    pdfmetrics.registerFont(TTFont("SongtiBold", font_path, subfontIndex=1))
    pdfmetrics.registerFontFamily("Songti", normal="Songti", bold="SongtiBold")
    body = ParagraphStyle("body", fontName="Songti", fontSize=10.5,
                          leading=16, wordWrap="CJK", spaceAfter=6)
    title = ParagraphStyle("title", parent=body, fontName="SongtiBold",
                           fontSize=18, leading=26, alignment=TA_CENTER,
                           spaceAfter=10, keepWithNext=True)
    identity = ParagraphStyle("identity", parent=body, alignment=TA_CENTER,
                              spaceAfter=10, keepWithNext=True)
    section = ParagraphStyle("section", parent=body, fontName="SongtiBold",
                             fontSize=13, leading=20, spaceBefore=6,
                             spaceAfter=8, keepWithNext=True)
    bullet = ParagraphStyle("bullet", parent=body, leftIndent=10,
                            firstLineIndent=-8)
    story = []
    text_lines = []
    image_hashes = {}
    for raw_line in original.decode("utf-8").splitlines():
        line = raw_line.strip()
        if not line:
            continue
        image_match = re.fullmatch(r"!\[([^]]*)\]\(([^)]+)\)", line)
        if image_match:
            path = (source.parent / image_match[2]).resolve()
            if path.name == "消抖计数.png":
                story.append(PageBreak())
            image_hashes[path] = sha256(path.read_bytes()).hexdigest()
            with PillowImage.open(path) as bitmap:
                width, height = bitmap.size
            max_width = 155 if path.name == "边沿检测.png" else 170
            scale = min(max_width * mm / width, 110 * mm / height)
            picture = Image(str(path), width=width * scale, height=height * scale)
            picture.hAlign = "CENTER"
            story.extend([Spacer(1, 5), picture, Spacer(1, 8)])
            continue
        style = body
        if line.startswith("# "):
            line = line[2:]
            style = title
        elif line.startswith("姓名："):
            style = identity
        elif re.match(r"^[一二三]、", line):
            style = section
        elif line.startswith("- "):
            line = line[2:]
            style = bullet
        visible = re.sub(r"`([^`]+)`", r"\1", line)
        text_lines.append(visible)
        prefix = "• " if style is bullet else ""
        story.append(Paragraph(prefix + escape(visible), style))
    for character in set("".join(text_lines)):
        if not character.isspace() and ord(character) not in pdfmetrics.getFont("Songti").face.charToGlyph:
            raise ValueError(f"Missing font glyph: {character!r}")

    def footer(canvas, document):
        canvas.saveState()
        canvas.setFont("Songti", 8.5)
        canvas.drawCentredString(A4[0] / 2, 10 * mm, str(document.page))
        canvas.restoreState()

    buffer = BytesIO()
    document = SimpleDocTemplate(
        buffer, pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm,
        topMargin=16 * mm, bottomMargin=20 * mm,
        title=text_lines[0], author="卢语上",
    )
    document.build(story, onFirstPage=footer, onLaterPages=footer)
    reader = PdfReader(BytesIO(buffer.getvalue()))
    extracted = re.sub(r"\s+", "", "".join(page.extract_text() or "" for page in reader.pages))
    for line in text_lines:
        if re.sub(r"\s+", "", line) not in extracted:
            raise ValueError(f"PDF text missing: {line}")
    actual_images = [len(page.images) for page in reader.pages]
    if actual_images != [1, 2, 1]:
        raise ValueError(f"Unexpected pagination/image distribution: {actual_images}")
    if source.read_bytes() != original:
        raise ValueError("Markdown changed during rendering")
    for path, digest in image_hashes.items():
        if sha256(path.read_bytes()).hexdigest() != digest:
            raise ValueError(f"Source image changed: {path}")
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("xb") as target:
        target.write(buffer.getvalue())
    print(f"PASS: {len(reader.pages)} pages, {len(text_lines)} text blocks, "
          f"{sum(actual_images)} images; Markdown and images unchanged.")
    print(f"Markdown SHA256: {sha256(original).hexdigest()}")
    print(output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path,
                        default=Path(__file__).resolve().parents[1] / "report/report.md")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    render(args.source.resolve(), args.output.resolve())
