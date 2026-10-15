"""Supplement process exits and existing exact oracle greps; never replace them."""
import argparse
import json
import re
from pathlib import Path

ANSI = re.compile(r"\x1b\[[0-?]*[ -/]*[@-~]")
CRITICAL = re.compile(
    r"^(?:SCRIPT ERROR:|ERROR:|FAIL\b|Parse Error:|Compile Error:|G0_PROBE_EXPECTED_FAILURE:)"
    r"|Assertion failed", re.IGNORECASE,
)
SUMMARY = re.compile(
    r"^(\w*REPORT)\s+executed=(\d+)\s+passed=(\d+)\s+failed=(\d+)(?:\s|$)"
)


def inspect_text(text: str) -> dict:
    errors, warnings, names = [], [], set()
    for number, raw in enumerate(text.splitlines(), 1):
        line = ANSI.sub("", raw).strip()
        if CRITICAL.search(line):
            errors.append(f"line {number}: {line}")
        if line.startswith("WARNING:"):
            warnings.append(f"line {number}: {line}")
        match = SUMMARY.match(line)
        if match:
            name, executed, passed, failed = match.groups()
            if name in names:
                errors.append(f"line {number}: duplicate summary {name}")
            names.add(name)
            if int(executed) <= 0 or int(executed) != int(passed) or int(failed) != 0:
                errors.append(f"line {number}: unsuccessful or inconsistent counts")
    return {"errors": errors, "warnings": warnings, "summaries": len(names)}


def read_log(path: Path) -> str:
    data = path.read_bytes()
    # PowerShell and Linux CI produce different encodings; invalid bytes fail closed.
    encoding = "utf-16" if data.startswith((b"\xff\xfe", b"\xfe\xff")) else "utf-8-sig"
    return data.decode(encoding)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("logs", nargs="+", type=Path)
    args = parser.parse_args()
    findings = []
    for path in args.logs:
        try:
            result = inspect_text(read_log(path))
        except (OSError, UnicodeError) as error:
            result = {"errors": [f"{type(error).__name__}: {error}"], "warnings": [], "summaries": 0}
        findings.append({"path": str(path), **result})
    failures = sum(len(item["errors"]) for item in findings)
    print("CI_LOG_GATE " + json.dumps({"files": findings, "errors": failures}, ensure_ascii=True))
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
