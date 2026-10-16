#!/usr/bin/env python3
"""P6: compare real Godot PNGs with human-approved Golden Images.

While approval is pending, produce SHA-256 candidate report without blocking.
Once approved, pin all 12 reference hashes and fail on meaningful pixel drift.
No automatic baseline promotion or external imaging dependencies.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import sys
import zlib

from validate_visual_snapshots import HUD_CASES, BOSS_CASES, png_dimensions

CASES = {**HUD_CASES, **BOSS_CASES}
CHANNEL_TOLERANCE = 16
MAX_CHANGED_FRACTION = 0.005
MAGIC = b"\x89PNG\r\n\x1a\n"


def check(ok, reason):
    if not ok:
        raise ValueError(reason)


def sha256(path):
    digest = hashlib.sha256()
    with path.open("rb") as fp:
        for chunk in iter(lambda: fp.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _unfilter(row, prev, channels, kind):
    if kind == 0:
        return row
    if kind == 1:
        for i in range(channels, len(row)):
            row[i] = (row[i] + row[i - channels]) & 255
    elif kind == 2:
        for i in range(len(row)):
            row[i] = (row[i] + prev[i]) & 255
    elif kind == 3:
        for i in range(len(row)):
            a = row[i - channels] if i >= channels else 0
            row[i] = (row[i] + ((a + prev[i]) // 2)) & 255
    elif kind == 4:
        for i in range(len(row)):
            a = row[i - channels] if i >= channels else 0
            b = prev[i]
            c = prev[i - channels] if i >= channels else 0
            guess = a + b - c
            da, db, dc = abs(guess - a), abs(guess - b), abs(guess - c)
            prediction = a if da <= db and da <= dc else (b if db <= dc else c)
            row[i] = (row[i] + prediction) & 255
    else:
        raise ValueError("Unsupported PNG filter %s" % kind)
    return row


def decode_png(path):
    """Decode non-interlaced 8-bit RGB or RGBA PNG into RGBA pixel bytes."""
    width, height = png_dimensions(path)
    raw = path.read_bytes()
    index, pieces, channels = 8, [], None
    while index + 12 <= len(raw):
        length = struct.unpack(">I", raw[index:index + 4])[0]
        kind = raw[index + 4:index + 8]
        content = raw[index + 8:index + 8 + length]
        if kind == b"IHDR":
            depth, color, comp, filt, interlace = struct.unpack("BBBBB", content[8:13])
            check(depth == 8 and color in (2, 6) and
                  comp == filt == interlace == 0, f"{path}: unsupported PNG mode")
            channels = 3 if color == 2 else 4
        elif kind == b"IDAT":
            pieces.append(content)
        elif kind == b"IEND":
            break
        index += length + 12
    check(channels is not None, f"{path}: missing image header")
    scanline = width * channels
    payload = zlib.decompress(b"".join(pieces))
    check(len(payload) == height * (scanline + 1), f"{path}: bad scanline length")
    result = bytearray(width * height * 4)
    previous, offset = bytearray(scanline), 0
    for y in range(height):
        row = bytearray(payload[offset + 1:offset + 1 + scanline])
        method = payload[offset]
        offset += 1 + scanline
        _unfilter(row, previous, channels, method)
        dest = y * width * 4
        if channels == 4:
            result[dest:dest + width * 4] = row
        else:
            for x in range(width):
                p, q = x * 3, dest + x * 4
                result[q:q + 4] = bytes((row[p], row[p + 1], row[p + 2], 255))
        previous = row
    return (width, height), result


def _chunk(kind, payload):
    crc = zlib.crc32(kind + payload) & 0xffffffff
    return struct.pack(">I", len(payload)) + kind + payload + struct.pack(">I", crc)


def save_diff(path, dimensions, rgba):
    width, height = dimensions
    check(len(rgba) == width * height * 4, "invalid diff image length")
    path.parent.mkdir(parents=True, exist_ok=True)
    stride = width * 4
    scan = bytearray()
    for y in range(height):
        scan.append(0)
        scan.extend(rgba[y * stride:(y + 1) * stride])
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    path.write_bytes(MAGIC + _chunk(b"IHDR", ihdr)
                     + _chunk(b"IDAT", zlib.compress(scan, 6))
                     + _chunk(b"IEND", b""))


def compare_images(baseline, actual, diff_path, tolerance=CHANNEL_TOLERANCE,
                   max_fraction=MAX_CHANGED_FRACTION):
    size, old = decode_png(baseline)
    current_size, new = decode_png(actual)
    check(size == current_size, "Golden Image and capture have different resolutions")
    changed, maximum = 0, 0
    heatmap = bytearray(len(new))
    for i in range(0, len(new), 4):
        delta = max(abs(int(old[i + k]) - int(new[i + k])) for k in range(4))
        maximum = max(maximum, delta)
        if delta > tolerance:
            changed += 1
            heatmap[i:i + 4] = b"\xff\x35\x24\xff"
        else:
            grey = (new[i] + new[i + 1] + new[i + 2]) // 12
            heatmap[i:i + 4] = bytes((grey, grey, grey, 255))
    save_diff(diff_path, size, heatmap)
    fraction = changed / (size[0] * size[1])
    return {"pixels": size[0] * size[1], "changed": changed,
            "changed_fraction": fraction, "max_channel_delta": maximum,
            "diff": str(diff_path), "pass": fraction <= max_fraction}


def approved_manifest(path):
    data = json.loads(path.read_text(encoding="utf-8"))
    check(isinstance(data, dict) and data.get("schema") == 1,
          "Golden Image manifest schema mismatch")
    check(data.get("status") in ("pending", "approved"),
          "baseline status must be pending or approved")
    check(data.get("case_ids") == sorted(CASES),
          "Golden Image case list differs from 12 capture fixtures")
    if data["status"] == "pending":
        check(data.get("images") == {}, "pending manifest cannot declare approved image hashes")
    else:
        for key in ("approved_by", "approved_on", "review_reference"):
            check(isinstance(data.get(key), str) and data[key].strip(),
                  f"Missing human approval provenance: {key}")
        check(isinstance(data.get("images"), dict) and set(data["images"]) == set(CASES),
              "Approved baseline must cover exactly 12 cases")
        for key, digest in data["images"].items():
            check(isinstance(digest, str) and re.fullmatch("[0-9a-f]{64}", digest),
                  f"Missing SHA-256 for {key}")
    return data


def render_report(report, output):
    output.mkdir(parents=True, exist_ok=True)
    (output / "visual_regression_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    state = report["status"]
    intro = {
        "pending_review": "No approved Golden Images yet. Current screenshots are candidates, not accepted baselines. CI remains nonblocking.",
        "pass": "Compared all 12 images against reviewed SHA-256-pinned Golden Images. Differences are within tolerance.",
        "fail": "Visual drift exceeds tolerance. Inspect diff heatmaps and seek human approval before updating the baseline.",
        "configuration_error": "Visual comparison configuration or input is invalid.",
    }[state]
    lines = ["### P6 Visual Regression: " + state.upper(), "", intro, "",
             "Threshold: per-pixel maximum RGBA channel delta > %d counts as changed; "
             "changed fraction must be <= %.2f%%." %
             (CHANNEL_TOLERANCE, 100 * MAX_CHANGED_FRACTION), "",
             "| Screenshot | Result | Changed pixels | Changed % |",
             "|---|---|---:|---:|"]
    for case in report.get("cases", []):
        fraction = case.get("changed_fraction")
        lines.append("| %s | %s | %s | %s |" % (
            case["id"], case["status"], case.get("changed", "—"),
            "—" if fraction is None else ("%.4f%%" % (100 * fraction))))
    lines.extend(["", "Artifact contains candidate SHA-256 inventory and diff heatmaps if approved.",
                  "Snapshots remain in the battle-visual-snapshots artifact.",
                  "Never infer baseline approval from test success.", ""])
    if report.get("message"):
        lines.append("Error: " + report["message"])
    (output / "visual_regression_summary.md").write_text(
        "\n".join(lines), encoding="utf-8")


def run(captures, baseline_manifest, output, run_id, attempt):
    check(run_id.isdigit() and attempt.isdigit(), "run-id and attempt must be numeric")
    manifest = approved_manifest(baseline_manifest)
    report = {"schema": 1,
              "status": "pending_review" if manifest["status"] == "pending" else "pass",
              "baseline_status": manifest["status"],
              "review_reference": manifest.get("review_reference"),
              "channel_tolerance": CHANNEL_TOLERANCE,
              "max_changed_fraction": MAX_CHANGED_FRACTION, "cases": []}
    for name in sorted(CASES):
        prefix = "v23" if name in HUD_CASES else "v31"
        actual = captures / (f"{prefix}_{run_id}_{attempt}") / (name + ".png")
        check(actual.is_file(), f"{name}: capture missing")
        check(png_dimensions(actual) == CASES[name][0], f"{name}: wrong image dimensions")
        entry = {"id": name, "candidate_sha256": sha256(actual)}
        if manifest["status"] == "pending":
            entry["status"] = "pending_review"
        else:
            reference = baseline_manifest.parent / "images" / (name + ".png")
            check(reference.is_file() and not reference.is_symlink(),
                  f"{name}: approved baseline missing or symlinked")
            check(sha256(reference) == manifest["images"][name],
                  f"{name}: approved baseline hash mismatch")
            result = compare_images(reference, actual,
                                    output / "diffs" / (name + "_diff.png"))
            entry.update(result)
            entry["status"] = "pass" if result["pass"] else "fail"
            if not result["pass"]:
                report["status"] = "fail"
        report["cases"].append(entry)
    render_report(report, output)
    print("VISUAL_REGRESSION_REPORT status=%s images=12 failed=%d" % (
        report["status"], sum(c["status"] == "fail" for c in report["cases"])))
    return 1 if report["status"] == "fail" else 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--captures", type=Path, required=True)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--attempt", required=True)
    args = parser.parse_args()
    try:
        return run(args.captures, args.baseline, args.output,
                   args.run_id, args.attempt)
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        render_report({"status": "configuration_error", "message": str(exc),
                       "cases": []}, args.output)
        print("VISUAL_REGRESSION_ERROR: " + str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
