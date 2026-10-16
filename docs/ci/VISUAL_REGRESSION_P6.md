# P6 — Visual Regression implementation and approval boundary

Date: 2026-10-16. Repository: KuroNekoLi/arbitrium-nexus-godot. This stage extends P5 without changing battle rules, legacy quota policy, or the existing 12 true-render fixtures.

## Evidence available at implementation time

- P5 real-render CI [Run 38844029056](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38844029056): validated **12 real PNGs**, 9 HUD + 3 Boss fixtures, with headless import and Xvfb/Mesa GL rendering; cache hit and artifact `battle-visual-snapshots` confirmed.
- [Current runtime visual review](../ui/BATTLE_UI_VISUAL_ACCEPTANCE.md) records the latest V3.5 rendering and interaction results. The target reference JPG is a design reference, not the same pixels as Godot output. The other historical screenshots are test receipts, not signed-off Golden Images.
- No approved `tests/visual_baselines/images/` existed. Initial baseline manifest is deliberately **pending**, never auto-populated from the latest CI.

## Automated pipeline

Within the existing `.github/workflows/godot-v2-3-visual-capture.yml`:

1. Shared Godot 4.7.2 + import cache; strict fresh import.
2. Existing real Xvfb/Mesa screenshots: 9 HUD variants and 3 mock-only Boss projection variants.
3. Existing `validate_visual_snapshots.py` checks signatures/CRC, dimensions, manifests and renderer.
4. New stdlib-only `compare_visual_snapshots.py` reads `tests/visual_baselines/approved.json` and emits one JSON/Markdown report. On pending status it records 12 candidate SHA-256 hashes and returns success **without claiming visual approval**. On approved status it validates review metadata, all 12 pinned baseline hashes, same PNG dimensions, and generates diff heatmaps. Significant drift (>16 maximum channel error on >0.5% pixels) returns exit code 1; config errors return 2.
5. Always upload `battle-visual-snapshots` (current PNGs, manifests, raw logs) and `visual-regression-evidence` (Markdown/JSON report and diff heatmaps). GitHub Job Summary repeats the state.
6. Python CI tests verify pending behavior, required approval evidence, same/near/mismatched images, diff PNG integrity, rejection of unreviewed baseline hashes and preservation of the protected historical GUI quota.

## Approval and guardrails

Follow [tests/visual_baselines/README.md](../../tests/visual_baselines/README.md). Approval requires **explicit human review** and a deliberately committed, SHA-256-pinned set of all 12 PNGs. Neither a green structural snapshot test nor Codex output is approval. CI does not change baseline images, approval metadata, or threshold values.

**Current status: BASELINE_PENDING — not a visual-regression acceptance pass.** A future owner review is needed to activate blocking pixel comparison.

## Limitations / further development

- One Boss encounter, projection-only Break; **not** coverage of multi-enemy targeting, actual GUI clicks, Last Spell recipient overlays, or final four-corner artistic quality.
- Software-render differences may occur across runner/driver or font versions. A single-run failure needs a repeatability check; no silent automatic retry or threshold relaxation.
- Per-pixel tolerance is global and intentionally conservative. It detects major movement and color shifts but cannot understand semantics; compare against human UX review.
- Full P4 contracts remain 25 suites/1149 assertions and Domain integration 26/1128. No removed tests or weakened strict log checks. Nightly 100-seed battle gate is unaffected.
