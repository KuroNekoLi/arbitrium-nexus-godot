#!/usr/bin/env python3
"""Validate real-window Godot PNGs/metadata without extra Python dependencies."""
import argparse
import json
from pathlib import Path
import struct
import zlib

HUD_CASES = {
    "v23_idle_1280_zh": ((1280, 720), "zh_TW", 4, False),
    "v23_idle_1920_zh": ((1920, 1080), "zh_TW", 4, False),
    "v23_idle_1280_en": ((1280, 720), "en", 4, False),
    "v23_idle_1920_en": ((1920, 1080), "en", 4, False),
    "v23_selected_1280_zh": ((1280, 720), "zh_TW", 4, True),
    "v23_hand8_1280_zh": ((1280, 720), "zh_TW", 8, False),
    "v23_hand8_1920_en": ((1920, 1080), "en", 8, False),
    "v23_hand1_1280_zh": ((1280, 720), "zh_TW", 1, False),
    "v23_hand0_1280_zh": ((1280, 720), "zh_TW", 0, False),
}
BOSS_CASES = {
    "v31_boss_break_1280_zh": ((1280, 720), "zh_TW"),
    "v31_boss_locked_1280_zh": ((1280, 720), "zh_TW"),
    "v31_boss_break_1920_en": ((1920, 1080), "en"),
}
PNG_MAGIC = b"\x89PNG\r\n\x1a\n"


def require(ok, reason):
    if not ok:
        raise ValueError(reason)


def png_dimensions(path):
    data = path.read_bytes()
    require(data.startswith(PNG_MAGIC), f"{path}: invalid PNG signature")
    pos, dimensions, idats, ended = 8, None, [], False
    while pos + 12 <= len(data):
        size = struct.unpack(">I", data[pos:pos + 4])[0]
        kind = data[pos + 4:pos + 8]
        end = pos + 12 + size
        require(end <= len(data), f"{path}: truncated PNG chunk")
        chunk = data[pos + 8:pos + 8 + size]
        crc = struct.unpack(">I", data[pos + 8 + size:end])[0]
        require(crc == zlib.crc32(kind + chunk) & 0xFFFFFFFF, f"{path}: corrupt PNG CRC")
        if pos == 8:
            require(kind == b"IHDR" and size == 13, f"{path}: missing IHDR")
        if kind == b"IHDR":
            require(dimensions is None and size == 13, f"{path}: duplicate IHDR")
            dimensions = struct.unpack(">II", chunk[:8])
            require(0 < dimensions[0] <= 4096 and 0 < dimensions[1] <= 4096,
                    f"{path}: PNG dimensions out of bounds")
        elif kind == b"IDAT":
            idats.append(chunk)
        elif kind == b"IEND":
            require(size == 0, f"{path}: invalid IEND")
            ended = True
            pos = end
            break
        pos = end
    require(ended and pos == len(data) and dimensions is not None,
            f"{path}: missing IEND or trailing data")
    require(bool(idats), f"{path}: no PNG pixel data")
    try:
        decoded = zlib.decompress(b"".join(idats))
    except zlib.error as exc:
        raise ValueError(f"{path}: invalid PNG pixel compression: {exc}") from exc
    require(len(decoded) > dimensions[1], f"{path}: empty decoded PNG pixel data")
    return dimensions


def require_renderer(metadata, label):
    server = str(metadata.get("display_server", "")).strip().lower()
    engine = str(metadata.get("godot", ""))
    require(server not in {"", "headless"}, f"{label}: capture must use windowed Godot")
    require(engine.startswith("4.7.2."), f"{label}: unexpected engine {engine!r}")


def verify_manifest(directory, name, expected, label, boss=False):
    metadata = json.loads((directory / name).read_text(encoding="utf-8"))
    require(isinstance(metadata, dict), f"{label}: invalid manifest object")
    require_renderer(metadata, label)
    if boss:
        require(metadata.get("fixture") == "MOCK_ONLY / projection layout",
                f"{label}: fixture must be explicitly mock-only")
    rows = metadata.get("cases")
    require(isinstance(rows, list) and all(isinstance(row, dict) for row in rows),
            f"{label}: cases must be objects")
    ids = [row.get("id") for row in rows]
    require(len(rows) == len(expected) and len(set(ids)) == len(expected)
            and set(ids) == set(expected), f"{label}: case inventory differs: {ids}")
    require({p.name for p in directory.glob("*.png")} ==
            {key + ".png" for key in expected}, f"{label}: unexpected PNG inventory")
    for row in rows:
        key = row["id"]
        dims, locale = expected[key][:2]
        require(tuple(row.get("viewport", ())) == dims and row.get("locale") == locale,
                f"{label}/{key}: viewport or locale mismatch")
        require(row.get("write") == "verified", f"{label}/{key}: writer failed")
        if boss:
            require(row.get("projection_fixture_only") is True, f"{label}/{key}: mock flag missing")
        else:
            require(row.get("ok") is True and tuple(row.get("observed_image", ())) == dims,
                    f"{label}/{key}: Godot image mismatch")
            require(row.get("hand_count") == expected[key][2]
                    and row.get("selected") is expected[key][3],
                    f"{label}/{key}: incorrect hand or selection")
            layout = row.get("layout")
            require(isinstance(layout, dict) and "EnemyStatus" in layout and "HandView" in layout,
                    f"{label}/{key}: HUD layout absent")
        require(png_dimensions(directory / (key + ".png")) == dims,
                f"{label}/{key}: PNG dimension mismatch")
    return len(rows)


def validate(base, run_id, attempt):
    require(run_id.isdigit() and attempt.isdigit(), "run-id/attempt must be numeric")
    hud = base / f"v23_{run_id}_{attempt}"
    boss = base / f"v31_{run_id}_{attempt}"
    require(hud.is_dir() and boss.is_dir(), "missing unique capture directories")
    a = verify_manifest(hud, "v23_capture_manifest.json", HUD_CASES, "HUD")
    b = verify_manifest(boss, "v31_boss_projection_fixture_manifest.json", BOSS_CASES,
                        "Boss", boss=True)
    for path in (hud / "v23_idle_1280_zh_thumb.jpg",
                 hud / "v23_selected_1280_zh_thumb.jpg",
                 boss / "v31_boss_break_thumb.jpg"):
        jpg = path.read_bytes()
        require(len(jpg) > 100 and jpg.startswith(b"\xff\xd8") and jpg.endswith(b"\xff\xd9"),
                f"{path}: missing or corrupted JPEG preview")
    return {"captures": a + b, "hud": a, "boss": b}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", type=Path, required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--attempt", required=True)
    args = parser.parse_args()
    r = validate(args.base, args.run_id, args.attempt)
    print("VISUAL_SNAPSHOT_REPORT captures={captures} hud={hud} boss={boss} failed=0".format(**r))


if __name__ == "__main__":
    main()
