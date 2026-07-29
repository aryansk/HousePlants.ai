#!/usr/bin/env python3
"""Repair asset metadata when a plant image file already exists locally."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "HousePlants" / "plants.json"
ASSETS = ROOT / "HousePlants" / "Assets.xcassets"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--apply",
        action="store_true",
        help="write repaired Contents.json files; default is a dry run",
    )
    args = parser.parse_args()

    plants = json.loads(CATALOG.read_text())["plant_catalog"]
    repairs: list[tuple[Path, str]] = []
    unresolved: list[str] = []

    for plant in plants:
        asset_name = Path(plant["images"]["main"]).stem
        imageset = ASSETS / f"{asset_name}.imageset"
        candidates = [
            path
            for suffix in (".jpg", ".jpeg", ".png")
            if (path := imageset / f"{asset_name}{suffix}").is_file()
        ]
        if not candidates:
            unresolved.append(f"{plant['id']} {plant['common_name']}")
            continue

        filename = candidates[0].name
        contents = imageset / "Contents.json"
        expected = {
            "images": [
                {"filename": filename, "idiom": "universal", "scale": "1x"},
                {"idiom": "universal", "scale": "2x"},
                {"idiom": "universal", "scale": "3x"},
            ],
            "info": {"author": "xcode", "version": 1},
        }
        current = json.loads(contents.read_text()) if contents.is_file() else None
        declared = [
            item.get("filename")
            for item in (current or {}).get("images", [])
            if item.get("filename")
        ]
        declared_file_exists = (
            len(declared) == 1 and (imageset / declared[0]).is_file()
        )
        if not declared_file_exists:
            repairs.append((contents, json.dumps(expected, indent=2) + "\n"))

    for path, payload in repairs:
        print(f"{'repairing' if args.apply else 'would repair'} {path.relative_to(ROOT)}")
        if args.apply:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(payload)

    for item in unresolved:
        print(f"unresolved image: {item}")

    print(
        f"metadata_repairs={len(repairs)} unresolved_images={len(unresolved)} "
        f"applied={args.apply}"
    )
    return 1 if unresolved else 0


if __name__ == "__main__":
    raise SystemExit(main())
