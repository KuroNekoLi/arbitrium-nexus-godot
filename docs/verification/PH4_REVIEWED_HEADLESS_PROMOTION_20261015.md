# P4 reviewed headless slice — scoped promotion gate (2026-10-15)

> Scope: **headless-verified components only**, isolated from incomplete P4.4 GUI and P4.5 playable UI. Source: `integration/p4-reviewed-20261015`. This is not a full Phase 4 approval or Level40 balance acceptance.

## Selected to promote
- `scripts/domain/m5/lv40/` eight content-aware adapters using the existing M5 reducer; seven reviewed M3/M4/M5 bridge files; never a parallel combat engine.
- Lv40 content fixture tests `test_lv40_content.gd` (37/37). `test_lv40_domain.gd` (83/83) and `test_lv40_edges.gd` (37/37) retained as tests without unauthorized fourth execution.
- Deterministic Lv40 policy source and balance-statistics helper + 35 named pure statistics tests; no 4-strategy × 100-seed Level40 **balance execution** claim.
- Profile metrics pure helper + 30 named tests; profiler CLI remains **GUI_NOT_VERIFIED**, no measured GPU benchmark or FPS claim.
- New narrow CI for content/statistics/metrics, M5.5 integration/replay and existing 100 seeded fixture battles.

## Source evidence & security boundaries
- Source reviewed branch full CI [#38715501522](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38715501522): success M1–M5.5, 100 seeds, P4 headless, metrics, profile, components, localization, readmodel.
- Source Lv40 edges third/final execution [#38714794598](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38714794598): 37/37 PASS. Lv40 domain third/final local recorded 83/83 in source checkpoint. Those two suite counts **do not run again**.
- Code has `BALANCE_PROVISIONAL` values, never USER_APPROVED balance.
- P4.4 GUI 14/16 third and refused new run; P4.5 true playable Level40 not implemented; no UI/HUD Scene and no new art is included in this promotion.
- Post-promote `master` must pass the **existing** Godot M5.5 full regression CI for actual master SHA. Until that result exists status is **PROMOTION_PENDING_MASTER_CI**, never claim full milestone complete.

See source [Round2 checkpoint](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/integration/p4-reviewed-20261015/docs/handoff/P4_ROUND2_REVIEW_CHECKPOINT_20261015.md).
