# P4 HUD component + feedback headless-only promotion (2026-10-15)

**Acceptance label:** `P4.4_HEADLESS_COMPONENTS_VERIFIED`, **NOT** `P4.4_GUI_VERIFIED`, **NOT** `P4.5_PLAYABLE`.

Promoted from `integration/p4-reviewed-20261015`:
- existing `battle_hud.gd` facade plus 9 small components and 8 reusable component scenes;
- event presentation `battle_actor.gd`, `battle_animation_director.gd`, `battle_cue_mapper.gd`, `battle_effects.gd`, the existing BattleScreen and Input Bindings;
- intentional `lv40_battle.tscn` with blocked play path; negative `test_p4_lv40_ui.gd` staging test asserts input is disabled and state empty;
- original headless tests 24/24 components, 45/45 feedback and 80/80 feedback-edges; previously verified P4.1=8, P4.2=36, P4.3=31, localization198, readmodel29.

**Excluded:** real GUI `test_p4_input_capture.gd` which was 14/16 third attempt (PNG save failed for two captures), screenshot assets, unverified GUI test execution, real Lv40 playable flag, real player playtesting, final game balance. No fourth GUI run without new explicit user approval. Do not relabel 10/10 staging as playable.

**Evidence:** previous full reviewed branch [#38715501522](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38715501522) Headless success, original source [Review Checkpoint](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/integration/p4-reviewed-20261015/docs/handoff/P4_ROUND2_REVIEW_CHECKPOINT_20261015.md). New scoped stage CI must pass before master. No Godot domain rewrite; all M5 rules remain canonical.
