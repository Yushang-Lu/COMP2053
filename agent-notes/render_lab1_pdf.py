"""Render Lab1's limited Markdown layout without editing sources or overwriting output."""

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
from reportlab.platypus import (
    Image, KeepTogether, PageBreak, Paragraph, SimpleDocTemplate, Spacer,
)


ROOT = Path(__file__).resolve().parents[1]
SONGTI = Path("/System/Library/Fonts/Supplemental/Songti.ttc")


def render(source, output, font, bold_font, font_index, bold_font_index):
    if output.exists():
        raise FileExistsError(f"Refusing to overwrite existing file: {output}")
    original = source.read_bytes()
    pdfmetrics.registerFont(TTFont("Songti", str(font), subfontIndex=font_index))
    pdfmetrics.registerFont(TTFont("SongtiBold", str(bold_font), subfontIndex=bold_font_index))
    pdfmetrics.registerFontFamily("Songti", normal="Songti", bold="SongtiBold")
    body = ParagraphStyle("body", fontName="Songti", fontSize=11, leading=17,
                          wordWrap="CJK", spaceAfter=5)
    title_style = ParagraphStyle("title", parent=body, fontName="SongtiBold",
                                fontSize=18, leading=25, alignment=TA_CENTER,
                                spaceAfter=12, keepWithNext=True)
    section_style = ParagraphStyle("section", parent=body, fontName="SongtiBold",
                                  fontSize=14, leading=21, spaceBefore=8,
                                  spaceAfter=8, keepWithNext=True)
    sub_style = ParagraphStyle("sub", parent=body, fontName="SongtiBold",
                              fontSize=12, leading=18, spaceBefore=6,
                              spaceAfter=7, keepWithNext=True)
    bullet_style = ParagraphStyle("bullet", parent=body, leftIndent=12, firstLineIndent=-9)
    story = []
    group = []
    text_lines = []
    image_count = 0

    def flush():
        if group:
            story.append(KeepTogether(group[:]))
            group.clear()

    for raw_line in original.decode("utf-8").splitlines():
        line = raw_line.strip()
        if not line:
            continue
        image = re.fullmatch(r"!\[([^]]*)\]\(([^)]+)\)", line)
        if image:
            path = source.parent / image[2]
            with PillowImage.open(path) as bitmap:
                width, height = bitmap.size
            target_width = 140 * mm if path.suffix.lower() in {".jpg", ".jpeg"} else 165 * mm
            picture = Image(str(path), width=target_width, height=target_width * height / width)
            picture.hAlign = "CENTER"
            group.extend([picture, Spacer(1, 7)])
            image_count += 1
            continue
        if line.startswith("# "):
            line = line[2:]
            flush()
            story.append(Paragraph(escape(line), title_style))
        elif re.match(r"^[一二三]、", line):
            flush()
            if line.startswith(("二、", "三、")):
                story.append(PageBreak())
            story.append(Paragraph(escape(line), section_style))
        elif line in {"使能无效：", "a+b：", "a-b："} or re.match(r"^2\.[12] ", line):
            flush()
            group.append(Paragraph(escape(line), sub_style))
        elif line.startswith("- "):
            flush()
            line = line[2:]
            story.append(Paragraph("• " + escape(line), bullet_style))
        else:
            paragraph = Paragraph(escape(line), body)
            if group:
                group.append(paragraph)
            else:
                story.append(paragraph)
        text_lines.append(line)
    flush()
    buffer = BytesIO()
    document = SimpleDocTemplate(
        buffer, pagesize=A4, rightMargin=20 * mm, leftMargin=20 * mm,
        topMargin=17 * mm, bottomMargin=17 * mm,
        title=text_lines[0] if text_lines else source.stem,
    )

    def footer(canvas, document):
        canvas.saveState()
        canvas.setFont("Songti", 9)
        canvas.drawCentredString(A4[0] / 2, 9 * mm, str(document.page))
        canvas.restoreState()

    document.build(story, onFirstPage=footer, onLaterPages=footer)
    if source.read_bytes() != original:
        raise RuntimeError("Markdown changed while rendering; output was not saved.")
    reader = PdfReader(BytesIO(buffer.getvalue()))
    pdf_text = "".join(page.extract_text() or "" for page in reader.pages)
    normalized_pdf = re.sub(r"\s+", "", pdf_text)
    for line in text_lines:
        if re.sub(r"\s+", "", line) not in normalized_pdf:
            raise RuntimeError(f"Missing PDF text: {line}")
    if sum(len(page.images) for page in reader.pages) != image_count:
        raise RuntimeError("PDF image count differs from the source.")
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("xb") as destination:
        destination.write(buffer.getvalue())
    print(f"Verified {len(reader.pages)} pages, all source text and {image_count} images.")
    print(f"Unchanged Markdown SHA256: {sha256(original).hexdigest()}")
    print(output)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=ROOT / "lab1/report/report.md")
    parser.add_argument("--output", type=Path, required=True, help="New PDF path; never overwritten")
    parser.add_argument("--font", type=Path, default=SONGTI)
    parser.add_argument("--bold-font", type=Path, default=SONGTI)
    parser.add_argument("--font-index", type=int, default=6)
    parser.add_argument("--bold-font-index", type=int, default=1)
    args = parser.parse_args()
    if args.output.suffix.lower() != ".pdf":
        parser.error("--output must end in .pdf")
    render(args.source.resolve(), args.output.resolve(), args.font, args.bold_font,
           args.font_index, args.bold_font_index)


if __name__ == "__main__":
    main()
