#!/usr/bin/env python3
"""Install a reviewed local image into one plant asset set.

This replaces the former network downloader. It never fetches or invents assets:
the caller must provide an already-reviewed JPEG or PNG.
"""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "HousePlants" / "plants.json"
ASSETS = ROOT / "HousePlants" / "Assets.xcassets"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("plant_id", help="Catalog id such as p_091")
    parser.add_argument("source", type=Path, help="Reviewed local JPEG or PNG")
    parser.add_argument("--quality", type=int, default=86)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    source = args.source.expanduser().resolve()
    if not source.is_file():
        raise SystemExit(f"source image not found: {source}")
    if source.suffix.lower() not in {".jpg", ".jpeg", ".png"}:
        raise SystemExit("source must be a JPEG or PNG")

    data = json.loads(CATALOG.read_text())
    plant = next(
        (item for item in data["plant_catalog"] if item["id"] == args.plant_id),
        None,
    )
    if plant is None:
        raise SystemExit(f"unknown plant id: {args.plant_id}")

    asset_name = Path(plant["images"]["main"]).stem
    imageset = ASSETS / f"{asset_name}.imageset"
    imageset.mkdir(parents=True, exist_ok=True)
    destination = imageset / f"{asset_name}.jpg"

    sips = Path("/usr/bin/sips")
    if sips.is_file():
        subprocess.run(
            [
                str(sips), "-z", "1024", "1024", "-s", "format", "jpeg",
                "-s", "formatOptions", str(args.quality), str(source),
                "--out", str(destination),
            ],
            check=True,
            stdout=subprocess.DEVNULL,
        )
    elif source.suffix.lower() in {".jpg", ".jpeg"}:
        shutil.copy2(source, destination)
    else:
        raise SystemExit("PNG conversion requires /usr/bin/sips on this machine")

    contents = {
        "images": [
            {"filename": destination.name, "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"},
        ],
        "info": {"author": "xcode", "version": 1},
    }
    (imageset / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n")
    print(f"installed {args.plant_id}: {destination.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
