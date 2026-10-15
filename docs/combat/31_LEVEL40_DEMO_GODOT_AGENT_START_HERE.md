# 31 — Lv40 Demo Boss: Godot Agent START HERE / Python v0.2 Handoff

> **Documentation status · 2026-10-15 — HISTORICAL_AGENT_HANDOFF_OTHER_REPOS**：文件引用 `astraea-combat-rules` 與 `Astraea-Academy` 為來源/早期工作目標；**現行 Godot 目標是本倉 `KuroNekoLi/arbitrium-nexus-godot`**。保留舊路徑追溯，不得讓 Codex 改錯 repo。 導覽：[Combat Spec Index](COMBAT_SPEC_INDEX.md)；未決：[Open Issues](COMBAT_OPEN_ISSUES.md)。M5.5 已完成 Headless Battle / Fixture 驗收（**1,238/1,238**；100 seeds + 100 Replay；[Master CI #38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741)）。**正式 Lv40 內容 Parity、完整可玩 Scene/玩家測試及平衡仍未驗證**。以下保留來源快照，不能解讀為此刻最新驗收。


> Created: 2026-10-15. **SPEC HANDOFF ONLY**. The Python v0.2 simulation and 11 local Python tests have executed. **Godot runtime parity, playable demo, CI and the balance acceptance gates have NOT passed.**
>
> Repositories: **specifications / Python** = `KuroNekoLi/astraea-combat-rules` (`master`); **actual Godot 4.7.2 project** = `KuroNekoLi/Astraea-Academy` (`main`, `godot/`). **Do not** use `KuroNekoLi/astraea-life-rpg` (legacy Flutter app) for this task.
>
> Read `AGENTS.md` in BOTH repositories before coding. Work in the Godot code repository only after an explicit implementation request, and first examine current implemented milestones and CI evidence. This handoff does not authorize rewriting existing systems.

## Mission and scope

Deliver **ONE playable three-actor, one-boss level-40 demo battle**. Players: `ren_swordsman_v1` (朝霧蓮 / sword), `akane_burst_mage_v1` (九條朱音 / burst mage), `tsumugi_healer_v1` (白石紬 / healer-support). Enemy: `demo_lvl40_arcane_sentry_v0_1` (秘紋守衛・零式). Initial main character role is SWORDSMAN; different future roles require unlocked Character Variants, **not** free in-battle role switching.

No second boss, free movement, commercial gacha, unrelated RPG overhaul, or imported `Counter-Function` mechanics.

## Source-of-truth and loading order

**Core authority**: most recent user-approved decisions > already approved P1/P2/M > `20` delegated engineering defaults > content and balance proposals. **Python heuristics never override the formal CombatDomain rules.** Do not reference deprecated `Life_RPG_Astraea_GDD_v1.1.md` or `COMBAT_SYSTEM.md` mechanics.

Read:
1. `docs/combat/00_README_COMBAT_RULES_BASELINE_V0_8.md` and core `01`–`24` modules, including `03` AP/MP/RP, `04` cards, `05` casting, `06` Boss, `07` Reaction, `08` Last Spell, `09` combos, `13` acceptance, `20` engineering edges, `21` acceptance (SPEC ONLY), `22` agent contract, `23` engineering milestones.
2. `docs/combat/25_STARTER_PARTY_CARD_CONTENT_V0_2.md`: three character candidates, card definitions `U01-U04`, `R01-R08`, `A01-A08`, `T01-T08`, unique variants, combos, Last Spells; numerical values PROVISIONAL.
3. `docs/combat/26_UNIVERSAL_BASIC_MAGIC_AND_STARTER_DECK_V0_3.md`: **newer override for starter decks**: `U05` universal BASIC HEAL, plus `T09/T10`; all three roles may equip UNIVERSAL attack/heal/Barrier. Actual decks are 12 per character, individual draw/hand/discard/casting, start hand4 and refill to4 (hand max8). `U05` is a card, not a free basic command. Healing without `Revive` never revives Incapacitated.
4. `docs/combat/27_LEVEL40_DEMO_BOSS_ENCOUNTER_V0_1.md`: encounter and B01–B11 deterministic Boss intent / phases, custom FIRE / ARCANE multipliers, `CORE_OPEN`, Break fallback, casting interruption, testcase DEMO-01–13.
5. `docs/combat/28_LEVEL40_PYTHON_BALANCE_PILOT_V0_1.md`: **historical Python v0.1 with a known offense-versus-self-defense bug**; never treat its 400-run results as the corrected baseline.
6. `docs/combat/29_LEVEL40_BOSS_PYTHON_V0_2_RESEARCH_AND_BALANCE_REPORT.md`: corrected Python v0.2, 15 parameter configurations × 8 heuristics × 100 seeds (12,000 prototype simulations), proposed balanced fixture.
7. `docs/combat/30_LEVEL40_GODOT_AGENT_HANDOFF_AFTER_PYTHON_V0_2.md`: detailed agent sequence G0→G5, source paths and test gates.

## Files and reproducibility

The same repository also has:
- `tools/balance/astraea_demo_python_sim_v0_2.py` — provisional Python simulator (not the Godot domain).
- `tools/balance/test_balance_v0_2.py` — **11 Python tests**, independently re-executed PASS in the model working container on 2026-10-15; this is not Godot test evidence.
- `tools/balance/run_scenarios.py` — runs the 15×8×100 seeded parameter sweep. Output CSV is *generated* (not manually authored canon).
- `tools/balance/demo_level40_balance_candidate_v0_2.json` — **BALANCE_PROVISIONAL** fixture override.
- `tools/balance/balance_scenario_summary_v0_2.json` — aggregate prototype KPI.
- `tools/balance/recommended_seed_82_balanced_trace.txt` — example simplified trace; not a domain oracle.

Run from the `tools/balance/` directory:

```bash
python3 test_balance_v0_2.py
python3 run_scenarios.py
# Generates all_scenarios_v0_2_12000_runs.csv and updated summary; use fixed seeds.
```

Raw 12,000-run CSV is also retained in ChatGPT Library `/docs/combat/python_balance_v0_2/all_scenarios_v0_2_12000_runs.csv` (not a primary source file); if exact historical results are required, compare generated output against the Library copy and record hashes. **Do not call tests passed if they were not actually run in the target environment.**

## Working Boss fixture candidate (NOT FINAL)

- Boss HP: **2700** (previous 3000).
- Boss attacks: v0.1 damage × **1.7** in Python candidate only; DO NOT also multiply transformed PAtk/MAtk after converting into Godot stats. Recompute and trace real skill pipeline rather than blindly doubling multipliers.
- BreakGaugeMax: **22** (previous 30); Boss PDef90/MDef85, P2 self Barrier180; Boss stages and B01–B11 from `27` remain.
- Level40 initial party and v0.3 starter decks remain as in `25/26`.
- Design target **8–12 player turns for balanced strategy**, not an alleged cross-RPG industry average. Prototype with candidate: balanced median12 (100/100 within24), aggressive median8 (100/100, at least one hero Incapacitated in35/100), defensive median18 (97/100 within24). These rates are not validated gameplay statistics; human policy sophistication and missing event rules remain significant limitations.
- In prototype: Break and Exposed remain underutilized. Do not blindly patch the core rules to force them to trigger. Verify card access, player policy, `CORE_OPEN` occurrence, legal turn timing first.

## Formal mechanics and risks the agent must not elide

- Shared player BaseAP6, not 6 AP per actor; RP from unused AP at end, expires after the following EnemyPhase; personal MP persists (no default auto-regen); 1 RP basic Guard, 2 RP basic Protect; legal SP Reaction must be in the *acting* character's hand and must be committed in a valid Reaction Window.
- Each actor has one free discard1/draw1 per PlayerPhase; disallow drawing the same discarded `CardInstance` immediately. No extra turn-wide actor action cap.
- Ordinary Full Chant uses the same MP as Chantless by default, pays upfront, resolves at the legal later point, can be disrupted with partial MP refund (not AP). Last Spell is its own slot, Full-only, one use, cannot voluntarily cancel, after release causes Exhausted. If caster HP reaches0 before release, **force invalidate** with no refund/no postmortem spell release. Consecutive destabilizations have special delay/attenuation logic not fully implemented by Python.
- Casting Disruption and Spell Counter differ; Break is not Exposed. Break replaces the next eligible Boss action with an explicit fallback; cannot retrospectively cancel already committed casting. Exposed is single-use by a later separate successful eligible SP; Analyze reveals Intel only and never directly sets Break/Exposed.
- Current Python v0.2 **does not implement full Reaction Queue / revalidation / skip events, complete ComboOpportunity FSM, full casting/stability events, all statuses or Last Spell second-destabilization weakening**. Explicitly test these in Godot against `20/21/27`.
- Boss Intent is public and stable: announced fixed target/range/protectability, no secret retarget upon player treatment, Charge and damage never happen as two free enemy actions within one slot.
- Localized zh-TW/en UI keys; no hard-coded player-facing strings; 2D/2.5D presentation only, no freely controlled movement.

## Godot implementation stages / acceptance gates

**G0** Inspect `KuroNekoLi/Astraea-Academy` actual branch and milestones M1–M5; DO NOT assume older AGENTS.md runtime status remains current. Record Godot binary/version and existing tests. Preserve unrelated academy scenes, saves, localization and assets.

**G1** Implement data-driven CharacterVariant, card, 12-instance loadout, Boss and Encounter fixtures; validate stable IDs and loadout eligibility; apply v0.3 U05 + T09/T10. Use provisional v0.2 Boss overrides only in a versioned content config.

**G2** Implement/verify DEMO-01–13 and the official phase tests. Include accepted/rejected actions, Reaction Queue ordering and skipped-cost atomicity, seeded card order, E2 charge → P3 decision → E3 resolve/interruption, `CORE_OPEN`→separate Exposed trigger → another SP finisher, BreakFallback action downgrade, ordinary/full casting cost and refund, Last Spell forced invalidation, dual kill VICTORY.

**G3** Compare deterministic Godot domain command tape/seed/state hash and KPI against **official rules**. Python is a directional comparator only. Record actual Godot CLI / Actions run logs and variations. A 12,000-run heuristic sweep is NOT proof the player demo is fun.

**G4** Render boss/HUD/card presenter driven only by authoritative DomainEvents, not animations controlling damage or outcome. Show three actors, their status, shared AP, Boss intent/HP/Break/Casting, selected actor hand and card details.

**G5** Run actual interactive playtest. Verify 8–12-turn target and real elapsed minutes for a typical player; demonstrate meaningful healing, guard/protect/reaction, interrupt or defense response to Charge, Exposed/Break and optional Last Spell. Use multiple deterministic QA seeds if one deal cannot show every mechanism; never secretly inject cards in ordinary gameplay.

Report milestones with Source→Test→Logs/Seed/Hash→Commit, preserve `NOT_VERIFIED` status until real evidence. Do not weaken canonical assertions, fabricate PASS, force push, or silently modify approved gameplay.

## Agent copy-paste kickoff

> Continue the existing Astraea-Academy Godot 4.7.2 project. Read both repos' AGENTS.md, pin the combat-rules commit with specs `00–31`, and begin with G0 audit of current code + tests. Implement only the Lv40 3v1 Arcane Sentry Type-0 playable demonstration. Use 25/26 for party and cards, 27 for boss encounter, 29 and `tools/balance/` as **non-authoritative Python balance evidence**, and 30/31 for handoff. Do not import old GDD/Counter-Function or override approved Combat Rules. Before any implementation, report the current M1–M5 state, gaps, tests, target commit, and scoped execution sequence; after implementation attach Godot CLI results, deterministic seeds, replay/state hashes and actual CI links.