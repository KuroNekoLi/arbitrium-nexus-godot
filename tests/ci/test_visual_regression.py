"""P6 Visual Regression: ownership, fail-closed pins and image-diff tests."""
import hashlib
import json
from pathlib import Path
import struct
import sys
import tempfile
import unittest
from unittest import mock
import zlib

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "ci"))
import compare_visual_snapshots as vr
from validate_visual_snapshots import png_dimensions


def chunk(kind, payload):
    return (struct.pack(">I", len(payload)) + kind + payload
            + struct.pack(">I", zlib.crc32(kind + payload) & 0xffffffff))


def rgba_png(pixels, width=2, height=2):
    """Independent fixture, PNG RGBA filter=0."""
    assert len(pixels) == width * height
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        for r, g, b, a in pixels[y * width:(y + 1) * width]:
            raw.extend((r, g, b, a))
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr)
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


class VisualRegressionTests(unittest.TestCase):
    def test_pending_manifest_proves_not_approved(self):
        manifest = vr.approved_manifest(ROOT / "tests/visual_baselines/approved.json")
        self.assertEqual("pending", manifest["status"])
        self.assertEqual(12, len(manifest["case_ids"]))
        self.assertEqual({}, manifest["images"])

    def test_visual_workflow_is_report_first_never_auto_promotes(self):
        source = (ROOT / ".github/workflows/godot-v2-3-visual-capture.yml").read_text()
        self.assertIn("python3 tools/ci/compare_visual_snapshots.py", source)
        self.assertIn("tests/visual_baselines/approved.json", source)
        self.assertIn("visual-regression-evidence", source)
        self.assertIn("battle-visual-snapshots", source)
        self.assertIn("tests/visual_baselines/**", source)
        self.assertNotIn("cp outputs/p4_input_capture", source)
        self.assertIn("V23_CAPTURE_REPORT executed=30 passed=30 failed=0", source)
        self.assertIn("V31_BOSS_RENDER_REPORT executed=20 passed=20 failed=0", source)

    def test_identical_tolerated_and_changed_images(self):
        pixels = [(10, 20, 30, 255)] * 4
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            original, current = folder / "baseline.png", folder / "capture.png"
            original.write_bytes(rgba_png(pixels))
            current.write_bytes(rgba_png(pixels))
            a = vr.compare_images(original, current, folder / "identical.png")
            self.assertTrue(a["pass"])
            self.assertEqual(0, a["changed"])
            self.assertEqual((2, 2), png_dimensions(folder / "identical.png"))
            small_noise = [(10, 20, 30, 255)] * 4
            small_noise[1] = (22, 20, 30, 255)  # delta=12 is ignored
            current.write_bytes(rgba_png(small_noise))
            b = vr.compare_images(original, current, folder / "tolerated.png")
            self.assertTrue(b["pass"])
            self.assertEqual(0, b["changed"])
            actual_change = [(10, 20, 30, 255)] * 4
            actual_change[0] = (255, 20, 30, 255)
            current.write_bytes(rgba_png(actual_change))
            c = vr.compare_images(original, current, folder / "moved.png")
            self.assertFalse(c["pass"])
            self.assertEqual(1, c["changed"])
            self.assertAlmostEqual(0.25, c["changed_fraction"])
            dims, data = vr.decode_png(folder / "moved.png")
            self.assertEqual((2, 2), dims)
            self.assertEqual(bytes((255, 53, 36, 255)), data[:4])

    def test_pending_then_approved_then_changed_no_auto_promotion(self):
        name = "v23_idle_1280_zh"
        pixels = [(5, 40, 100, 255)] * 4
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            actual_dir = folder / "captures/v23_1_1"
            actual_dir.mkdir(parents=True)
            current = actual_dir / (name + ".png")
            current.write_bytes(rgba_png(pixels))
            baseline = folder / "baseline"
            baseline.mkdir()
            manifest_path = baseline / "approved.json"
            output = folder / "output"
            def store(data):
                manifest_path.write_text(json.dumps(data), encoding="utf-8")
            with mock.patch.dict(vr.CASES, {name: ((2, 2), "zh_TW", 4, False)}, clear=True):
                store({"schema": 1, "status": "pending", "case_ids": [name], "images": {}})
                self.assertEqual(0, vr.run(folder / "captures", manifest_path, output, "1", "1"))
                record = json.loads((output / "visual_regression_report.json").read_text())
                self.assertEqual("pending_review", record["status"])
                self.assertEqual(hashlib.sha256(current.read_bytes()).hexdigest(),
                                 record["cases"][0]["candidate_sha256"])
                self.assertFalse((baseline / "images").exists())
                (baseline / "images").mkdir()
                pinned = baseline / "images" / (name + ".png")
                pinned.write_bytes(current.read_bytes())
                store({"schema": 1, "status": "approved", "case_ids": [name],
                       "approved_by": "human-reviewer", "approved_on": "2026-10-16",
                       "review_reference": "review-ticket-123",
                       "images": {name: vr.sha256(pinned)}})
                self.assertEqual(0, vr.run(folder / "captures", manifest_path, output, "1", "1"))
                current.write_bytes(rgba_png([(255, 40, 100, 255)] + pixels[1:]))
                self.assertEqual(1, vr.run(folder / "captures", manifest_path, output, "1", "1"))
                self.assertEqual("fail", json.loads(
                    (output / "visual_regression_report.json").read_text())["status"])
                self.assertEqual((2, 2), png_dimensions(output / "diffs" / (name + "_diff.png")))

    def test_unapproved_hashes_and_missing_review_are_rejected(self):
        key = "v23_idle_1280_zh"
        with tempfile.TemporaryDirectory() as directory:
            file = Path(directory) / "approved.json"
            with mock.patch.dict(vr.CASES, {key: ((2, 2), "zh_TW", 4, False)}, clear=True):
                file.write_text(json.dumps({"schema": 1, "status": "approved",
                                            "case_ids": [key], "images": {key: "a" * 64}}))
                with self.assertRaisesRegex(ValueError, "provenance"):
                    vr.approved_manifest(file)
                file.write_text(json.dumps({"schema": 1, "status": "pending",
                                            "case_ids": [key], "images": {key: "a" * 64}}))
                with self.assertRaisesRegex(ValueError, "pending manifest"):
                    vr.approved_manifest(file)


if __name__ == "__main__":
    unittest.main()
