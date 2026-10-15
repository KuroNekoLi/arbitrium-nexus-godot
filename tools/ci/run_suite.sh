#!/usr/bin/env bash
set -Eeuo pipefail
# run_suite.sh test_suite:REPORT_NAME:expected_count output_directory
IFS=: read -r suite marker expected <<< "${1:?missing suite:marker:count}"
dir="${2:?missing output directory}"
mkdir -p "$dir"
log="$dir/$suite.log"
: "${GODOT_BIN:?Godot executable not configured}"
if ! timeout 180s "$GODOT_BIN" --headless --path . \
  --script "res://tests/$suite.gd" > "$log" 2>&1; then
  tail -n 140 "$log"
  exit 1
fi
if ! grep -Fxq "$marker executed=$expected passed=$expected failed=0" "$log"; then
  echo "Missing or mismatched acceptance report for $suite" >&2
  tail -n 140 "$log"
  exit 1
fi
python3 tools/ci/assert_godot_logs.py "$log"
if [[ "$suite" == "test_m5_integration" ]]; then
  grep -Fxq "M5_5_GOLDEN_FULL_BATTLE_VERIFIED" "$log"
fi
if [[ "$suite" == "test_m5_replay" ]]; then
  grep -Fxq "M5_5_FULL_TAPE_REPLAY_VERIFIED" "$log"
fi
grep -F "$marker executed=" "$log"
