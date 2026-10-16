"""CI-only Godot project sanitization must not alter gameplay settings."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools" / "ci"))
from prepare_project import prepare_project


class PrepareProjectTests(unittest.TestCase):
    def test_only_editor_vcs_settings_are_removed(self):
        source = ('[application]\nrun/main_scene="res://battle.tscn"\n'
                  '[editor]\nversion_control/plugin_name="GitPlugin"\n'
                  'version_control/autoload_on_startup=true\n'
                  'other_editor_setting=123\n'
                  '[editor_plugins]\nenabled=PackedStringArray("res://addons/example/plugin.cfg")\n')
        result = prepare_project(source)
        self.assertNotIn('version_control/plugin_name', result)
        self.assertNotIn('version_control/autoload_on_startup', result)
        self.assertIn('run/main_scene="res://battle.tscn"', result)
        self.assertIn('other_editor_setting=123', result)
        self.assertIn('editor_plugins', result)
        self.assertEqual(result, prepare_project(result))

    def test_other_sections_keep_similarly_named_keys(self):
        source = '[custom]\nversion_control/plugin_name="value"\n'
        self.assertEqual(source, prepare_project(source))


if __name__ == "__main__":
    unittest.main()
