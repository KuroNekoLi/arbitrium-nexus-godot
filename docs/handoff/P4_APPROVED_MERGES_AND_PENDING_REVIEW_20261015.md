# Phase 4 — approved selective merges & unresolved branches (2026-10-15)

> STATUS: **SCOPED_HEADLESS_PROMOTED / GUI_AND_PLAYABLE_NOT_VERIFIED**. The user's permission applies to tested changes only. No whole-branch merge or PR; no force-push; no unauthorized fourth GUI/Lv40 Domain/Lv40 Edges execution.

## Exact master promotions

| Stage | Master commit | Premerge CI | Scope |
|---|---|---|---|
| 1 | [`c2796e312317baaf4bdcebbb6295927b00ff364a`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/c2796e312317baaf4bdcebbb6295927b00ff364a) | [#38717257405](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38717257405) Success | 24 files: Lv40 Domain/M3–M5 bridges + content37, prior-attempt domain83/edge37 fixtures, 35-stat and 30-profiler pure unit tests. **No 4th restricted test** |
| 2 | [`d4d5b9986fc4d8d51227566dccc7573ddbae87df`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/d4d5b9986fc4d8d51227566dccc7573ddbae87df) | [#38718051812](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38718051812) Success | en/zh_TW Level40 text, 26 card appearance resources, CommandFactory, detached ReadModel, localization 198/198 and readmodel29/29 |
| 3 | [`f40686cda795aa61035f7473b08c8730409655b6`](https://github.com/KuroNekoLi/arbitrium-nexus-godot/commit/f40686cda795aa61035f7473b08c8730409655b6) | [#38718716573](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38718716573) Success | HUD refactor + scene components, VFX cues/director, headless component24/24, feedback45/45 + edge80/80; Lv40 UI remains **intentionally disabled** (10/10 staging). **GUI 14/16 NOT VERIFIED** |
| 4 | This documentation/manifest update (read actual commit SHA in GitHub) | Docs/license-only | Four existing Kenney vfx/sfx source/license records added to `assets/asset_manifest.csv` and this report; code from stage 3 unchanged |

**Postpromotion official evidence:** Stage 1 `master` had 18 successful workflow runs on `c2796e31` (including M5.5 full). Stage 2 `master` completed its own tests including [M5.5 #38718467597](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38718467597). Stage 3 Headless [Master #38718980511](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38718980511) succeeded; full M5.5 [#38718980475](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38718980475) must be checked for final status, not presumed successful from preceding runs.

## Branch review result

Branches inspected: `handoff/p4-lv40-chat-20261015`, `handoff/p4-card-localization-chat-20261015`, `handoff/p4-readmodel-chat-20261015`, `handoff/p4-balance-research-chat-20261015`, `handoff/p4-performance-qa-chat-20261015`, `handoff/p4-encounter-ui-chat-20261015`, `ui/hud-visual-refactor-20261015`, `handoff/p4-dispatch-index-20261015`, and historical `phase3/m5-3-boss-break-exposed-combo`, `phase3/m5-4-outcome-core01`, `phase3/m5-5-full-battle-replay`.

Compared complete Git tree blob SHAs of reviewed source `integration/p4-reviewed-20261015` against the post-promotion `master`. All current reviewed runtime sources and previously passing functional/safety suites have now been copied; only the following **nonidentical code/evidence** items remain:

| File / group | Why not promoted |
|---|---|
| `tests/test_p4_input_capture.gd` | **Original GUI 14/16 FAIL**: precisely `P43-CAPTURE-p4_3_drag_1280` and `P43-CAPTURE-p4_3_eight_1920` fail `save_png`; user explicitly refused fourth GUI execution. Its `--capture-prefix` support can isolate future filenames but **must not be run without new approval** |
| `tests/test_lv40_balance.gd` | True multi-policy Lv40 balance study **NOT_EXECUTED**; existing 35 pure metrics tests are not equivalent |
| `tests/capture_p4_feedback.gd`, `tests/capture_p4_lv40_ui.gd` | Capture/visual evidence not executed and reviewed as images on this merged SHA |
| `resources/combat/lv40/pending_integration.patch` | Historical patch, not runtime. Reviewed Lv40 M5 source is already integrated |
| `.github/workflows/godot-m5-5-acceptance.yml` from old reviewed branch | Older branch-specific workflow experiments contain expired edge-attempt step. **Do not overwrite current master gates**; new staged scoped workflows preserve proven counts and avoid exhausted test budgets |
| `tests/*attempt1.log`, `outputs/p4_logs/*`, `outputs/p4_review/*` | Historical raw evidence stays on reviewed source branch, not shipped as source files |

The one unique file in `handoff/p4-dispatch-index-20261015` is `docs/handoff/P4_CHAT_DISPATCH_INDEX.md`, a superseded dispatch plan, not unmerged production code. No historical Phase3 branch should be merged whole: master has already accepted their behavior and modern code. **Caution:** existence/blobs check is not an exhaustive semantic diff/line-by-line code review of every old commit; any genuinely novel unmerged behavior requires isolated new tests and authority verification.

## Outstanding approval / engineering gates

1. **P4.4 GUI NOT VERIFIED**: 14/16 on third authorized capture attempt; missing two PNG writes. Need *new explicit user approval* before retrying same runner, even with collision-isolating prefix. Headless 45+80 PASS is distinct evidence.
2. **P4.5 Level40 Playable NOT VERIFIED**: `scripts/battle/battle_screen.gd` `encounter_profile=lv40` remains fail-closed; `tests/test_p4_lv40_ui.gd` **10/10 PASS means correctly blocked input**, not playable. Next work requires a new isolated branch connecting real Encounter config/initial to Controller, Adapter, CardFactory, target/mode/LastSpell/Reaction, full tape, terminal, reentry; preserve old fixture.
3. **P4.6 Balance/GPU/human NOT VERIFIED**: 4 strategies×100 actual Lv40 seeds, measured GUI GPU/performance, true player playtest and approved numeric balance are absent. `BALANCE_PROVISIONAL` stays provisional.
4. **Original worker branches review**: file/sha audit is complete; true line-by-line old-workflow patch audit is still incomplete. The updated review branch [full report](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/integration/p4-reviewed-20261015/docs/handoff/P4_PENDING_BRANCH_REVIEW_20261015.md) keeps detailed per-worker refs and current known gaps.

## Technical learning

Why staged cherry-picks instead of merge? A Git branch can include **tested domain code and unverified GUI/capture code in one commit history**. Promoting only file-specific reviewed source into a clean descendant of `master`, running strict import, assertion summaries and log-gates, prevents historical branches from overwriting the canonical Domain Reducer. The negative Lv40 shell is intentionally tested as fail-closed; a passing negative test never validates a positive playable feature. CI success is scoped to the exact SHA and tests executed.

**Next owner action:** implement real Lv40 UI in an isolated feature branch and run new positive playable tests, but respect exhausted prior GUI/Lv40 edge rerun restrictions.
