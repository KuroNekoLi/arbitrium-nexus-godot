# P4 Pending Branch Review — scoped promotion and unresolved work (2026-10-15)

> **Status: REVIEW_IN_PROGRESS / UNVERIFIED_PARTS_NOT_MERGED.** User authorized selective promotion of fixes proven by real tests, not wholesale merge of UI/Playtest failures. Never force-push or erase local uncommitted work.

## What was promoted safely (separate clean-room branches)

| Source scope | Staged SHA / verification | Master promotion scope |
|---|---|---|
| Lv40 domain, authorized approved content + M3/M4/M5 bridges, tests; pure balance/profile metrics | `c2796e312317baaf4bdcebbb6295927b00ff364a`; [stage Actions #38717257405](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38717257405) SUCCESS | Fast-forwarded to master as **HEADLESS-ONLY**, not P4.5 playable or P4.6 actual profiling; pre-existing Lv40 domain83/83 + edges37/37 had exhausted three-test budget and were not rerun |
| Card i18n / 26 appearances / deterministic ReadModel + pure CommandFactory | `d4d5b9986fc4d8d51227566dccc7573ddbae87df`; [stage Actions #38718051812](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38718051812) SUCCESS | Await explicit fast-forward + master CI; tested 198/198 Localization, 29/29 ReadModel, old Scene8/HUD36/P4.3 31; does **not** activate Lv40 BattleScreen |

All source changes were narrowed via path/blob-selection, **not** merging the 200+ files of the reviewed integration branch. [Original review checkpoint](P4_ROUND2_REVIEW_CHECKPOINT_20261015.md) remains authoritative on prior allowed test attempts and blocked GUI.

## Active branches and differences against integrated review source

A full directory/tree and branch comparison was performed. These observations are **file presence and changed-blob checks**, not a claim every line in all 200+ diffs has been peer-reviewed.

| Branch | Last inspected SHA | Review classification |
|---|---|---|
| `handoff/p4-lv40-chat-20261015` | `8c24c568` | Its files exist in reviewed integration; Lv40 B05/B06 published cycle fix and other reviewed corrections are *newer* than source. **Do not replace corrected lv40_boss.gd with older copy** |
| `handoff/p4-card-localization-chat-20261015` | `7274fff4` | Source files present; reviewed integration corrected mismatched `LV40_Uxx_NAME` mapping; exact keys and 198 test coverage used for scoped promotion |
| `handoff/p4-readmodel-chat-20261015` | `31d364b7` | ReadModel and factory source present; 29/29 test covers detached state, command sanitization. May be promoted separately without enabling the unverified Lv40 UI |
| `handoff/p4-balance-research-chat-20261015` | `0efaea66` | Statistics tool present; paired-seed/percentile/hash validation fixed in reviewed integration, 35/35 pure tests. 4 strategies ×100 Lv40 battles **NOT EXECUTED** |
| `handoff/p4-performance-qa-chat-20261015` | `e5912d0f` | Profile metric tool present, CLI large integer overflow corrected and 30/30 PASS with strict error-free log. **GUI GPU benchmark NOT VERIFIED** |
| `handoff/p4-encounter-ui-chat-20261015` | `4053c2ad` | Lv40 UI only **contract-blocked staging**. Existing 10/10 verifies no live Controller/snapshot and safe disabled input; not a playable P4.5 feature |
| `ui/hud-visual-refactor-20261015` | `c45ccdc7` | Component tree present and revised in integration (24/24 contract headless); original missing controls reintroduced via facade. **P4.4 GUI Input 14/16 NOT VERIFIED** — hold HUD runtime merge |
| `handoff/p4-dispatch-index-20261015` | `9423f674` | Only tree-missing unique file is `docs/handoff/P4_CHAT_DISPATCH_INDEX.md`, a historical agent assignment index **not runtime code**. No reason to merge old divergent code |
| `engineering/ci-evidence-gate-20261015` | `e4468a75` | Already present in original master; **no extra cherry-pick** |
| `phase3/m5-3-boss-break-exposed-combo` | `1615d340` | Divergent historical implementation; current M5.3 was already canonical and tested. Do not merge old engine tree |
| `phase3/m5-4-outcome-core01` | `df3e39cb` | Divergent historical implementation; M5.4 CORE-01/02 already part of current master Domain suite |
| `phase3/m5-5-full-battle-replay` | `2b47e42b` | Divergent historical implementation; M5.5 1238 assertion baseline and 100seed replay are canonical; full branch would overwrite modern files |

**Review limitation**: original six package source branches, old three Phase3 branches and one HUD branch have not been line-by-line audited for *unmerged novel semantics*. They must be reviewed as **specific patches** with test IDs, not by whole-branch merge or assuming SHA ancestry means equivalence.

## Concrete blockers and suggested next changes

### P4.4 GUI Input 14/16
From `outputs/p4_logs/p44_input_attempt3.log`, the failed named assertions were exactly **P43-CAPTURE-p4_3_drag_1280** and **P43-CAPTURE-p4_3_eight_1920**. Both log Godot `ERROR: Can't save PNG at path .../outputs/p4_3_*.png`. Fourteen other assertions including keyboard, card payment, reaction/phase, bounded hand and locale passed. **This is a PNG-write evidence gap, not proof screenshots were valid.** The existing `tests/test_p4_input_capture.gd` already supports `--capture-prefix=<unique>` for collision isolation; use a new unique prefix/clean output path when **and only when** the owner authorizes a fourth GUI attempt. Never rename the suite to bypass exhausted budget. Without authorization: `P4.4 GUI = NOT VERIFIED`.

### P4.5 real playable Level40 UI
`scripts/battle/battle_screen.gd` still intentionally blocks the `lv40` encounter profile; current `test_p4_lv40_ui.gd` validates a **disabled/no snapshot** safety gate, not live play. Required implementation (as a new reversible branch): pass actual `Encounter.config/initial` through Controller/CommandFactory/ReadModel, support target/mode/LastSpell/Reaction, preserve old fixture defaults, add **new** playable integration tests (complete attack to outcome, deterministic tape/semantic parity and scene reentry). Only after new tests should replace **staging-only** oracles with separately versioned playable contracts. Do not weaken current negative gate just to report green.

### P4.6 actual testing
The pure stats 35 and pure profiler 30 are good foundations. **Real** Lv40 policy × multiple seeds, logged 4-strategy 100 seeded battles, actual GUI 1280/1920 GPU/CPU measurements, formal balance adoption, image inspection and human playtest remain unverified; none should be reported as done.

### Preservation & ownership
- Keep original reviewed branch alive as evidence. Source [Actions #38715501522](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38715501522) success on Headless state; [#38714794598](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38714794598) successful **third and final** Lv40 edges. These are not automatic pass claims for new UI work.
- No PR; merge only scoped tests-covered units. No force-push. Do not destroy original local workspace/caches. `BALANCE_PROVISIONAL` never upgraded via engineering test.
