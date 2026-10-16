# Godot GitHub Actions caching (2026-10-16)

## What is used
- `ci-fast.yml`: headless smoke and P4 presentation contracts, two independent jobs.
- `ci-integration.yml`: named M1–M5.5 domain regression and legacy smoke.
- `ci-full.yml`: scheduled / release / core-change full gate invoking `godot-m5-5-acceptance.yml`, including **100 seeded battles**.
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
For active visual-capture workflows, reuse the same composite setup action and retain Xvfb / genuine viewport screenshot assertions. Do not replace real Godot screenshots with generated images. Legacy workflows are intentionally left intact unless they become active maintenance targets.
