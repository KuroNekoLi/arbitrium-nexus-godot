# Godot GitHub Actions caching (2026-10-16)

## What is used
- `ci-fast.yml`: representative headless smoke (single job, normally each relevant push). 
- `ci-p4-contracts.yml`: full 25-suite / 1149-assertion P4 headless UI contract gate for UI/scene/assets/test changes; runs nightly and manually for cross-domain coverage. Legacy prototype suites are no longer duplicated here.
- `ci-integration.yml`: 26 named M1–M5.5 domain suites, 1128 assertions; early prototype legacy smoke suites were removed from this daily gate in P4.
- `ci-full.yml`: scheduled (02:00 Asia/Taipei), manual, and release-published full gate invoking `godot-m5-5-acceptance.yml`, including **100 seeded battles and deterministic Replay**. It does not trigger on ordinary push or PR. The retired eight-card prototype smoke suites are intentionally absent.
- `godot-v2-3-visual-capture.yml` (`CI Visual - Real Godot Battle Screenshots`) now uses the same verified Godot/import cache and verifies 12 genuine viewport PNGs + manifests before exporting artifact `battle-visual-snapshots`.
- Earlier phase workflows remain callable; they are not rewritten or silently deleted.

## Shared setup
`.github/actions/setup-godot-ci/action.yml` restores the **checksum-verified** Godot 4.7.2 binary, then the incremental Godot import cache, and finally disables unavailable editor-only Git VCS startup in the runner checkout. The existing `tools/ci/install_godot.sh` always verifies the executable SHA-512 and version, including after a cache hit. The original local `project.godot` is unchanged.

Cache keys encode Linux runner, Godot version, and asset/scene/import dependencies. The `restore-keys` prefix allows reusing unchanged imported assets when one source changes; a **fresh** `godot --headless --editor --import` must still run every job so stale, missing, new, or changed files are imported. No cache hit counts as a passing test. If a cached resource fails strict import or log checks the job still fails.

`.godot/imported/` and `.godot/uid_cache.bin` are disposable generated artifacts. Do not cache logs, tests' pass markers, screenshots, exports, or mutable application data. GitHub Actions cache is immutable per exact key, may be evicted, and is scoped by branch/default-branch access. Cold runs still download and import.

## Timing and troubleshooting
- Each job summary reports `Binary exact hit` and `Imported assets exact hit`.
- Compare `Install`, `import`, and end-to-end job durations across cold and warm runs. Restoration overhead can outweigh gains on small imports.
- GitPlugin import errors on hosted runners are addressed by stripping only `[editor]` VCS settings from the transient CI checkout; never weaken `assert_godot_logs.py`.
- When changing engine version, platform, import semantics, or addons, bump the `godot-import-...-v1` cache namespace.
- Existing 100-seed tests, expected counts, and negative failure probes are not changed.

## Future extension
Active real-render capture now reuses the composite action and Xvfb/Mesa. Its real PNGs and manifests are checked and uploaded (no image generation or pixel-diff claim). Historical workflows remain untouched.

## P6 Visual Regression outputs

Visual comparison reuses the same real screenshots, Godot/import caches and the stdlib Python environment (no added dependency/download). PNG candidate hashes, reviewed-baseline comparisons and heatmaps are GitHub **Artifacts** (not `actions/cache`). The `tests/visual_baselines/images/` directory is intentionally empty until a human explicitly approves images and pins their SHA-256 in `approved.json`.
