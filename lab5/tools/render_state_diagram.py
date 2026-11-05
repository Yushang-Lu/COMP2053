"""Generate matching editable draw.io, SVG, and optional PDF preview."""

import argparse
from html import escape
import math
from pathlib import Path
import xml.etree.ElementTree as ET

from reportlab.pdfgen import canvas
from reportlab.pdfbase.pdfmetrics import stringWidth


WIDTH = 1400
HEIGHT = 1000
STATES = {
    "IDLE": (300, 260, "00", "dout <= 1"),
    "START": (1000, 260, "01", "dout <= 0"),
    "DATA": (1000, 620, "10", "dout <= data_reg[bit_index]"),
    "STOP": (300, 620, "11", "dout <= 1"),
}
EDGES = [
    (None, "IDLE", [(60, 260), (175, 260)], ["rst = 1"], (95, 225)),
    ("IDLE", "START", [(425, 260), (875, 260)], ["valid = 1"], (650, 230)),
    ("IDLE", "IDLE", [(240, 205), (170, 150), (430, 150), (360, 205)],
     ["valid = 0"], (300, 120)),
    ("START", "START", [(1060, 205), (1120, 150), (880, 150), (940, 205)],
     ["bit_count != 10415"], (1000, 120)),
    ("START", "DATA", [(1000, 325), (1000, 555)],
     ["bit_count == 10415"], (1160, 440)),
    ("DATA", "STOP", [(875, 620), (425, 620)],
     ["bit_count == 10415", "&& bit_index == 7"], (650, 565)),
    ("DATA", "DATA", [(1060, 675), (1120, 730), (880, 730), (940, 675)],
     ["bit_count != 10415", "|| bit_index != 7"], (1000, 780)),
    ("STOP", "IDLE", [(300, 555), (300, 325)],
     ["bit_count == 10415"], (145, 440)),
    ("STOP", "STOP", [(240, 675), (170, 730), (430, 730), (360, 675)],
     ["bit_count != 10415"], (300, 780)),
]
NOTES = [
    (700, 48, ["uart_send: four-state FSM (100 MHz, 9600 baud, 8N1)"], 26),
    (700, 870, ["Registered outputs: rules inside states execute at posedge clk using pre-edge values."], 21),
    (700, 902, ["dout therefore lags state / bit_index changes by one clock (10 ns); each bit lasts 10416 clocks."], 21),
    (700, 934, ["bit_count: 0..10415 per bit. DATA bit_index: 0..7, increments at bit_count == 10415."], 21),
    (700, 966, ["rst = 1 asynchronously resets any state to IDLE, dout to 1, and counters / data_reg to 0."], 21),
]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path,
                        default=Path(__file__).resolve().parents[1] / "resource")
    parser.add_argument("--preview-pdf", type=Path)
    args = parser.parse_args()
    paths = [args.output_dir / f"uart_send-state.{suffix}" for suffix in ("svg", "drawio")]
    if args.preview_pdf:
        paths.append(args.preview_pdf)
    for path in paths:
        if path.exists():
            raise FileExistsError(path)
        path.parent.mkdir(parents=True, exist_ok=True)

    svg = ET.Element("svg", xmlns="http://www.w3.org/2000/svg",
                     viewBox=f"0 0 {WIDTH} {HEIGHT}", width=str(WIDTH), height=str(HEIGHT))
    ET.SubElement(svg, "rect", width=str(WIDTH), height=str(HEIGHT), fill="white")
    pdf = canvas.Canvas(str(args.preview_pdf), pagesize=(WIDTH, HEIGHT)) if args.preview_pdf else None
    if pdf:
        pdf.setTitle("Lab5 uart_send state diagram")
    mxfile = ET.Element("mxfile", host="app.diagrams.net")
    diagram = ET.SubElement(mxfile, "diagram", name="uart_send", id="uart-send")
    model = ET.SubElement(diagram, "mxGraphModel", page="1", pageWidth=str(WIDTH),
                          pageHeight=str(HEIGHT), grid="1", gridSize="10")
    root = ET.SubElement(model, "root")
    ET.SubElement(root, "mxCell", id="0")
    ET.SubElement(root, "mxCell", id="1", parent="0")
    label_index = 0

    def text(lines, center_x, baseline_y, size=21, mx=True):
        nonlocal label_index
        for offset, line in enumerate(lines):
            baseline = baseline_y + offset * (size + 5)
            element = ET.SubElement(svg, "text", x=str(center_x), y=str(baseline),
                                    fill="#111111", **{"text-anchor": "middle",
                                    "font-family": "Arial, sans-serif", "font-size": str(size)})
            element.text = line
            if pdf:
                pdf.setFillColorRGB(0.07, 0.07, 0.07)
                pdf.setFont("Helvetica", size)
                pdf.drawCentredString(center_x, HEIGHT - baseline, line)
        if mx:
            label_index += 1
            label_width = max(stringWidth(line, "Helvetica", size) for line in lines) + 20
            cell = ET.SubElement(root, "mxCell", id=f"label-{label_index}",
                                 value="<br>".join(escape(line) for line in lines),
                                 style=f"text;html=1;align=center;verticalAlign=middle;fontSize={size};",
                                 vertex="1", parent="1")
            ET.SubElement(cell, "mxGeometry", x=str(center_x - label_width / 2),
                          y=str(baseline_y - size), width=str(label_width),
                          height=str(len(lines) * (size + 5)), **{"as": "geometry"})

    for edge_index, (source, target, points, lines, label_position) in enumerate(EDGES):
        ET.SubElement(svg, "polyline", points=" ".join(f"{point[0]},{point[1]}" for point in points),
                      fill="none", stroke="#222222", **{"stroke-width": "2"})
        end_x, end_y = points[-1]
        prev_x, prev_y = points[-2]
        angle = math.atan2(end_y - prev_y, end_x - prev_x)
        arrow = [(end_x, end_y)]
        for delta in (-0.45, 0.45):
            arrow.append((end_x - 13 * math.cos(angle + delta),
                          end_y - 13 * math.sin(angle + delta)))
        ET.SubElement(svg, "polygon", points=" ".join(f"{point[0]},{point[1]}" for point in arrow),
                      fill="#222222")
        if pdf:
            pdf.setStrokeColorRGB(0.13, 0.13, 0.13)
            pdf.setFillColorRGB(0.13, 0.13, 0.13)
            pdf.setLineWidth(2)
            for first, second in zip(points, points[1:]):
                pdf.line(first[0], HEIGHT - first[1], second[0], HEIGHT - second[1])
            path = pdf.beginPath()
            path.moveTo(arrow[0][0], HEIGHT - arrow[0][1])
            for point in arrow[1:]:
                path.lineTo(point[0], HEIGHT - point[1])
            path.close()
            pdf.drawPath(path, stroke=0, fill=1)
        style = "html=1;endArrow=block;endFill=1;rounded=0;strokeWidth=2;"
        attributes = {"id": f"edge-{edge_index}", "edge": "1", "parent": "1",
                      "target": target}
        for terminal, state, point in [("exit", source, points[0]), ("entry", target, points[-1])]:
            if state:
                center_x, center_y = STATES[state][:2]
                style += (f"{terminal}X={(point[0] - center_x + 125) / 250};"
                          f"{terminal}Y={(point[1] - center_y + 65) / 130};{terminal}Perimeter=0;")
        if source:
            attributes["source"] = source
        cell = ET.SubElement(root, "mxCell", style=style, **attributes)
        geometry = ET.SubElement(cell, "mxGeometry", relative="1", **{"as": "geometry"})
        if not source:
            ET.SubElement(geometry, "mxPoint", x=str(points[0][0]), y=str(points[0][1]),
                          **{"as": "sourcePoint"})
        if len(points) > 2:
            waypoints = ET.SubElement(geometry, "Array", **{"as": "points"})
            for point in points[1:-1]:
                ET.SubElement(waypoints, "mxPoint", x=str(point[0]), y=str(point[1]))
        text(lines, *label_position)

    for name, (center_x, center_y, encoding, output) in STATES.items():
        ET.SubElement(svg, "ellipse", cx=str(center_x), cy=str(center_y), rx="125", ry="65",
                      fill="white", stroke="#222222", **{"stroke-width": "2"})
        if pdf:
            pdf.setFillColorRGB(1, 1, 1)
            pdf.ellipse(center_x - 125, HEIGHT - center_y - 65,
                        center_x + 125, HEIGHT - center_y + 65, stroke=1, fill=1)
        text([f"{name} ({encoding})"], center_x, center_y - 9, 24, mx=False)
        text([output], center_x, center_y + 24, 17, mx=False)
        cell = ET.SubElement(root, "mxCell", id=name,
                             value=f"{name} ({encoding})<br>{escape(output)}",
                             style="ellipse;html=1;whiteSpace=wrap;fontSize=19;fillColor=#ffffff;strokeWidth=2;",
                             vertex="1", parent="1")
        ET.SubElement(cell, "mxGeometry", x=str(center_x - 125), y=str(center_y - 65),
                      width="250", height="130", **{"as": "geometry"})
    for center_x, baseline_y, lines, size in NOTES:
        text(lines, center_x, baseline_y, size)
    ET.indent(svg)
    ET.indent(mxfile)
    ET.ElementTree(svg).write(paths[0], encoding="utf-8", xml_declaration=True)
    ET.ElementTree(mxfile).write(paths[1], encoding="utf-8", xml_declaration=True)
    if pdf:
        pdf.showPage()
        pdf.save()
    print("Generated:", ", ".join(str(path) for path in paths))


if __name__ == "__main__":
    main()
