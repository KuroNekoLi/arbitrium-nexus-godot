#!/usr/bin/env python3
"""Remove workstation-only Godot VCS editor settings from the CI checkout.

Only edits the ephemeral checkout, never commits a project.godot change.
The Godot GitPlugin extension is not installed on hosted runners.
"""
from pathlib import Path
import sys

EDITOR_ONLY_KEYS = {
    "version_control/plugin_name",
    "version_control/autoload_on_startup",
}


def prepare_project(source: str) -> str:
    section = ""
    result = []
    for line in source.splitlines(keepends=True):
        stripped = line.strip()
        if stripped.startswith("[") and stripped.endswith("]"):
            section = stripped[1:-1]
        key = stripped.split("=", 1)[0].strip() if "=" in stripped else ""
        if section == "editor" and key in EDITOR_ONLY_KEYS:
            continue
        result.append(line)
    return "".join(result)


if __name__ == "__main__":
    target = Path(sys.argv[1] if len(sys.argv) > 1 else "project.godot")
    original = target.read_text(encoding="utf-8")
    updated = prepare_project(original)
    if updated != original:
        target.write_text(updated, encoding="utf-8")
        print("CI_PROJECT_PREPARED: disabled editor-only GitPlugin configuration")
    else:
        print("CI_PROJECT_PREPARED: no editor VCS configuration present")
