#!/usr/bin/env python3
"""Render the homelab's D2 diagrams, or check that committed SVGs are current.

Run from any directory. Requires Python 3 and the D2 version pinned in mise.toml.
Set D2_BIN to use an explicit D2 binary without installing it globally.
"""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[4]
SOURCE = ROOT / "docs/assets/diagrams/sources"
OUTPUT = SOURCE.parent
D2_VERSION = "v0.9.0"
RENDER_FLAGS = [
    "--layout=elk",
    "--theme=200",
    "--pad=24",
    "--bundle=true",
    "--elk-padding=[top=38,left=26,bottom=26,right=26]",
    "--elk-nodeNodeBetweenLayers=40",
]


def check_bundled(svg: bytes, source: Path) -> None:
    """Prevent exported diagrams from needing network access to load their icons."""
    root = ET.fromstring(svg)
    for element in root.iter():
        for attribute, value in element.attrib.items():
            if attribute.rsplit("}", 1)[-1] == "href":
                if value and not value.startswith(("#", "data:")):
                    raise ValueError(f"{source.name}: unbundled asset: {value}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--check", action="store_true", help="Render to a temporary directory and fail if SVGs differ."
    )
    args = parser.parse_args()
    sources = sorted(SOURCE.glob("*.d2"))
    if not sources:
        parser.error(f"No D2 sources found in {SOURCE}")

    requested_binary = os.environ.get("D2_BIN", "d2")
    binary = shutil.which(requested_binary)
    if not binary:
        parser.error("D2 is unavailable. Run `mise install d2` and `mise exec -- python3 <this-script>`, or set D2_BIN.")
    version = subprocess.run(
        [binary, "version"], check=True, capture_output=True, text=True
    ).stdout.strip()
    if version != D2_VERSION:
        parser.error(f"Expected D2 {D2_VERSION}, found {version}. Use the version pinned in mise.toml.")

    rendered = []
    try:
        with tempfile.TemporaryDirectory(prefix="homelab-d2-render-") as scratch:
            for source in sources:
                temporary = Path(scratch) / (source.stem + ".svg")
                subprocess.run(
                    [binary, *RENDER_FLAGS, "--salt=homelab-" + source.stem, str(source), str(temporary)],
                    cwd=SOURCE,
                    check=True,
                    capture_output=True,
                    text=True,
                )
                svg = temporary.read_bytes()
                check_bundled(svg, source)
                rendered.append((OUTPUT / temporary.name, svg))
    except subprocess.CalledProcessError as error:
        parser.exit(1, error.stderr or str(error))
    except (ET.ParseError, ValueError) as error:
        parser.exit(1, str(error) + "\n")

    stale = []
    for destination, svg in rendered:
        if args.check:
            if not destination.exists() or destination.read_bytes() != svg:
                stale.append(str(destination.relative_to(ROOT)))
        else:
            destination.write_bytes(svg)
            print(destination.relative_to(ROOT))
    if stale:
        print("Regenerate D2 diagrams: " + ", ".join(stale))
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
