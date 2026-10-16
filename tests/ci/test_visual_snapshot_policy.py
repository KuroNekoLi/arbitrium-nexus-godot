"""P5: keep genuine real-render snapshots and strict output contract."""
from pathlib import Path
import struct
import sys
import tempfile
import unittest
import zlib

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "ci"))
from validate_visual_snapshots import BOSS_CASES, HUD_CASES, png_dimensions, require_renderer, validate


def chunk(kind, value):
    return (struct.pack(">I", len(value)) + kind + value
            + struct.pack(">I", zlib.crc32(kind + value) & 0xFFFFFFFF))


def small_png():
    width, height = 2, 2
    raw = (b"\x00" + b"\x25\x66\x99\xff" * width) * height
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b""))


class SnapshotPolicyTests(unittest.TestCase):
    def test_preserve_all_cases(self):
        self.assertEqual(9, len(HUD_CASES))
        self.assertEqual(3, len(BOSS_CASES))
        self.assertIn("v23_hand0_1280_zh", HUD_CASES)
        self.assertIn("v31_boss_break_1920_en", BOSS_CASES)

    def test_check_png_and_corrupt_crc(self):
        with tempfile.TemporaryDirectory() as folder:
            file = Path(folder) / "capture.png"
            valid = small_png()
            file.write_bytes(valid)
            self.assertEqual((2, 2), png_dimensions(file))
            bad = bytearray(valid)
            bad[28] ^= 0x12
            file.write_bytes(bad)
            with self.assertRaisesRegex(ValueError, "CRC"):
                png_dimensions(file)
            file.write_bytes(valid[:-5])
            with self.assertRaises(ValueError):
                png_dimensions(file)

    def test_no_headless_or_wrong_engine(self):
        with self.assertRaisesRegex(ValueError, "windowed"):
            require_renderer({"display_server": "headless", "godot": "4.7.2.stable"}, "HUD")
        with self.assertRaisesRegex(ValueError, "engine"):
            require_renderer({"display_server": "x11", "godot": "4.6.0.stable"}, "HUD")
        require_renderer({"display_server": "x11", "godot": "4.7.2.stable"}, "HUD")
        require_renderer({"display_server": "x11", "godot": "4.7.2-stable (official)"}, "HUD")

    def test_missing_outputs_fail_closed(self):
        with tempfile.TemporaryDirectory() as folder:
            with self.assertRaisesRegex(ValueError, "missing unique"):
                validate(Path(folder), "1", "1")
            with self.assertRaisesRegex(ValueError, "numeric"):
                validate(Path(folder), "bad", "1")

    def test_workflow_keeps_real_renderer_and_historical_quota(self):
        y = (ROOT / ".github/workflows/godot-v2-3-visual-capture.yml").read_text()
        self.assertIn("uses: ./.github/actions/setup-godot-ci", y)
        self.assertNotIn("curl -fLsS", y)
        self.assertIn("xvfb-run", y)
        self.assertIn("--rendering-method gl_compatibility", y)
        self.assertIn("python3 tools/ci/validate_visual_snapshots.py", y)
        self.assertIn("battle-visual-snapshots", y)
        self.assertIn("'scenes/battle/**'", y)
        self.assertIn("'assets/**'", y)
        self.assertIn("V23_CAPTURE_REPORT executed=30 passed=30 failed=0", y)
        self.assertIn("V31_BOSS_RENDER_REPORT executed=20 passed=20 failed=0", y)
        self.assertIn("Final authorized V26 pending UX attempt", y)
        self.assertIn("github.event.before == '0000000000000000000000000000000000000000'", y)
        self.assertNotIn("V23_IMAGE_BASE64_BEGIN", y)


if __name__ == "__main__":
    unittest.main()
