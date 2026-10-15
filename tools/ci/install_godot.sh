#!/usr/bin/env bash
set -Eeuo pipefail
out="$PWD/.ci-cache/godot-4.7.2"
zip="Godot_v4.7.2-stable_linux.x86_64.zip"
bin="$out/Godot_v4.7.2-stable_linux.x86_64"
if [[ -x "$bin" ]] && (cd "$out" && sha512sum -c binary.sha512) &&
   "$bin" --version | grep -q '^4\.7\.2\.'; then
  echo "Using checksum-verified cached Godot 4.7.2"
else
  rm -rf "$out"
  mkdir -p "$out"
  release="https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable"
  curl -fLsS --retry 3 "$release/$zip" -o "$out/$zip"
  curl -fLsS --retry 3 "$release/SHA512-SUMS.txt" -o "$out/SHA512-SUMS.txt"
  (cd "$out" && grep -F "$zip" SHA512-SUMS.txt > selected.sha512 &&
    test "$(wc -l < selected.sha512)" -eq 1 && sha512sum -c selected.sha512)
  unzip -q "$out/$zip" -d "$out/extracted"
  extracted="$(find "$out/extracted" -type f -name 'Godot_v4.7.2-stable_linux.x86_64' -print -quit)"
  test -n "$extracted"
  mv "$extracted" "$bin"
  chmod +x "$bin"
  (cd "$out" && sha512sum ./Godot_v4.7.2-stable_linux.x86_64 > binary.sha512)
  rm -rf "$out/extracted" "$out/$zip"
fi
"$bin" --version
if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "GODOT_BIN=$bin" >> "$GITHUB_ENV"
else
  echo "GODOT_BIN=$bin"
fi
