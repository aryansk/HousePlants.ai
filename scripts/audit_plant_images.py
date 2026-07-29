#!/usr/bin/env python3
"""Validate the plant catalog against the Xcode asset catalog."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_CATALOG = ROOT / "HousePlants" / "plants.json"
DEFAULT_ASSETS = ROOT / "HousePlants" / "Assets.xcassets"


def dimensions(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if data.startswith(b"\x89PNG\r\n\x1a\n") and len(data) >= 24:
        return struct.unpack(">II", data[16:24])
    if data.startswith(b"\xff\xd8"):
        offset = 2
        sof_markers = {
            0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7,
            0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF,
        }
        while offset + 4 <= len(data):
            while offset < len(data) and data[offset] != 0xFF:
                offset += 1
            while offset < len(data) and data[offset] == 0xFF:
                offset += 1
            if offset >= len(data):
                break
            marker = data[offset]
            offset += 1
            if marker in {0xD8, 0xD9}:
                continue
            if offset + 2 > len(data):
                break
            segment_length = struct.unpack(">H", data[offset:offset + 2])[0]
            if marker in sof_markers and offset + 7 <= len(data):
                height, width = struct.unpack(">HH", data[offset + 3:offset + 7])
                return width, height
            offset += segment_length
    raise ValueError("unsupported or corrupt image")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--catalog", type=Path, default=DEFAULT_CATALOG)
    parser.add_argument("--assets", type=Path, default=DEFAULT_ASSETS)
    parser.add_argument("--min-edge", type=int, default=700)
    parser.add_argument("--max-aspect", type=float, default=1.35)
    parser.add_argument("--warn-bytes", type=int, default=450_000)
    parser.add_argument("--json", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    errors: list[str] = []
    warnings: list[str] = []
    hashes: dict[str, list[str]] = defaultdict(list)

    try:
        plants = json.loads(args.catalog.read_text())["plant_catalog"]
    except (OSError, KeyError, json.JSONDecodeError) as error:
        raise SystemExit(f"cannot read catalog: {error}")

    seen_ids: set[str] = set()
    for plant in plants:
        plant_id = plant.get("id", "<missing-id>")
        if plant_id in seen_ids:
            errors.append(f"{plant_id}: duplicate catalog id")
        seen_ids.add(plant_id)

        reference = plant.get("images", {}).get("main", "")
        if not reference:
            errors.append(f"{plant_id}: empty images.main")
            continue

        asset_name = Path(reference).stem
        imageset = args.assets / f"{asset_name}.imageset"
        contents_path = imageset / "Contents.json"
        if not contents_path.is_file():
            errors.append(f"{plant_id}: missing {contents_path}")
            continue
        try:
            contents = json.loads(contents_path.read_text())
        except json.JSONDecodeError as error:
            errors.append(f"{plant_id}: invalid Contents.json: {error}")
            continue

        filenames = [
            item["filename"]
            for item in contents.get("images", [])
            if item.get("filename")
        ]
        if len(filenames) != 1:
            errors.append(
                f"{plant_id}: expected one declared image file, found {len(filenames)}"
            )
            continue

        image_path = imageset / filenames[0]
        if not image_path.is_file() or image_path.stat().st_size == 0:
            errors.append(f"{plant_id}: missing or empty {image_path}")
            continue

        try:
            width, height = dimensions(image_path)
        except ValueError as error:
            errors.append(f"{plant_id}: {error}: {image_path}")
            continue

        if min(width, height) < args.min_edge:
            errors.append(
                f"{plant_id}: {width}x{height} is below min edge {args.min_edge}"
            )
        ratio = max(width, height) / min(width, height)
        if ratio > args.max_aspect:
            errors.append(
                f"{plant_id}: {width}x{height} exceeds aspect {args.max_aspect:.2f}"
            )
        if image_path.stat().st_size > args.warn_bytes:
            warnings.append(
                f"{plant_id}: {image_path.stat().st_size} bytes exceeds warning threshold"
            )

        digest = hashlib.sha256(image_path.read_bytes()).hexdigest()
        hashes[digest].append(plant_id)

    for ids in hashes.values():
        if len(ids) > 1:
            errors.append(f"exact duplicate image shared by {', '.join(ids)}")

    result = {
        "plants": len(plants),
        "errors": errors,
        "warnings": warnings,
    }
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        for message in errors:
            print(f"ERROR {message}")
        for message in warnings:
            print(f"WARN  {message}")
        print(
            f"plants={len(plants)} errors={len(errors)} warnings={len(warnings)}"
        )
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
