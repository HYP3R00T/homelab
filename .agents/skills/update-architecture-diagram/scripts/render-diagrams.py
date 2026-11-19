#!/usr/bin/env python3
"""Render homelab diagram sources with Python's standard library.

Usage: python3 .agents/skills/update-architecture-diagram/scripts/render-diagrams.py [--check]
The sources describe declared architecture and layout, not live cluster status.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / "docs/assets/diagrams/sources"
OUTPUT = SOURCE.parent
COLORS = {
    "blue": "#7cb5ff",
    "teal": "#68dfcd",
    "violet": "#b7a1ff",
    "amber": "#eac17a",
    "muted": "#9bacc4",
}


def render(spec: dict) -> str:
    """Keep explicit positions so small changes do not rearrange the diagram."""
    width, height = spec["width"], spec["height"]
    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" '
        f'viewBox="0 0 {width} {height}" role="img" aria-labelledby="title description">',
        f'<title id="title">{escape(spec["title"])}</title>',
        f'<desc id="description">{escape(spec["description"])}</desc>',
        '<defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" '
        'markerWidth="7" markerHeight="7" orient="auto-start-reverse">'
        '<path d="M 0 0 L 10 5 L 0 10 z" fill="#7188a6"/></marker></defs>',
        '<style>text{font-family:ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,Segoe UI,sans-serif}'
        '.heading{font-size:29px;font-weight:700;fill:#eff5ff}'
        '.sub{font-size:18px;fill:#a8bdd7}'
        '.label{font-size:21px;font-weight:650;fill:#eff5ff}'
        '.body{font-size:18px;fill:#b8cbe2}'
        '.note{font-size:17px;fill:#9fb4d0}'
        '.tag{font-size:14px;font-weight:700;letter-spacing:1.3px}</style>',
        f'<rect width="{width}" height="{height}" rx="24" fill="#0b1220"/>',
        f'<text class="heading" x="32" y="48">{escape(spec["title"])}</text>',
        f'<text class="sub" x="32" y="77">{escape(spec["subtitle"])}</text>',
    ]
    for group in spec.get("groups", []):
        x, y, width, height = group["box"]
        color = COLORS[group.get("color", "blue")]
        out.append(
            f'<rect x="{x}" y="{y}" width="{width}" height="{height}" rx="18" '
            'fill="#101c2d" stroke="#2c405b" stroke-width="1.5"/>'
        )
        out.append(
            f'<text class="tag" x="{x + 22}" y="{y + 29}" fill="{color}">'
            f'{escape(group["label"])}</text>'
        )

    # Connectors sit behind cards, following the source's explicit paths.
    for edge in spec.get("edges", []):
        dash = ' stroke-dasharray="6 6"' if edge.get("dashed") else ""
        out.append(
            f'<path d="{escape(edge["path"])}" fill="none" stroke="#7188a6" '
            f'stroke-width="2"{dash} marker-end="url(#arrow)"/>'
        )
        if edge.get("label"):
            x, y = edge["at"]
            out.append(
                f'<text class="note" x="{x}" y="{y}">{escape(edge["label"])}</text>'
            )

    for node in spec.get("nodes", []):
        x, y, width, height = node["box"]
        color = COLORS[node.get("color", "blue")]
        out.append(
            f'<rect x="{x}" y="{y}" width="{width}" height="{height}" rx="12" '
            f'fill="#142237" stroke="{color}" stroke-opacity=".6"/>'
        )
        out.append(
            f'<rect x="{x + 1}" y="{y + 15}" width="3" height="{height - 30}" '
            f'rx="1.5" fill="{color}"/>'
        )
        out.append(
            f'<text class="label" x="{x + 19}" y="{y + 31}">'
            f'{escape(node["title"])}</text>'
        )
        for index, line in enumerate(node.get("lines", [])):
            out.append(
                f'<text class="body" x="{x + 19}" y="{y + 59 + index * 23}">'
                f'{escape(line)}</text>'
            )

    for note in spec.get("notes", []):
        out.append(
            f'<text class="note" x="{note["x"]}" y="{note["y"]}">'
            f'{escape(note["text"])}</text>'
        )
    out.append("</svg>")
    return "\n".join(out) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check", action="store_true", help="Fail if an SVG differs from its source."
    )
    args = parser.parse_args()
    sources = sorted(SOURCE.glob("*.json"))
    if not sources:
        parser.error(f"No diagram sources found in {SOURCE}")

    stale = []
    for source in sources:
        destination = OUTPUT / (source.stem + ".svg")
        svg = render(json.loads(source.read_text()))
        if args.check:
            if not destination.exists() or destination.read_text() != svg:
                stale.append(str(destination.relative_to(ROOT)))
        else:
            destination.write_text(svg)
            print(destination.relative_to(ROOT))

    if stale:
        print("Regenerate diagrams: " + ", ".join(stale))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
