# Lv40 Domain Wiring — GPT return to Codex (2026-10-15)

## Identity

- Package: **Lv40 Domain wiring ONLY** (Phase 4.5, within the already-authorized M5 extension).
- Repository: `KuroNekoLi/arbitrium-nexus-godot`.
- Checkpoint branch: `handoff/p4-lv40-chat-20261015`.
- Full original input SHA: `977a289654e1470bcda83c6c25c14d4cda4c86ab`.
- Source master / P4.3 base: `5103e40a4b95da82f2561b29c2604e9514fd398b`.
- Latest code + verification-note commit before this return: `5e2d0d2f8fd821988a455f2ad95c6515987b88fa`.
- Final branch HEAD: retrieve at review time; return document and patch are additional WIP commits.
- Output: 11 modified GDScript files (8 implementation + 3 test) and updated `docs/verification/PH4_LV40_DOMAIN_NOTE.md`; unified diff at `docs/handoff/LV40_DOMAIN_WIRING.patch`.
- Missing execution inputs: local Godot 4.7.2 binary, local repository checkout and execution environment. The GitHub connector can read and write this checkpoint, **not** execute Godot.
- **Status: IMPLEMENTED_NOT_VERIFIED / NOT_EXECUTED.** These changes have been committed **only to the checkpoint branch**. Do not merge master, stamp P4.5 VERIFIED or claim CI PASS.

## Changes

| Exact path | Mode | Boundary / change | Rule / why |
|---|---|---|---|
| `scripts/domain/m5/integration/m5_domain_resolver.gd` | MODIFY | Opt-in Lv40 dispatch after existing M5 untrusted-payload / balance / terminal guards | Single public transaction M5.apply; legacy fixture unchanged |
| `scripts/domain/m3/phase/phase_engine.gd` | MODIFY | Existing declared-action + window guards call Lv40Boss.resolve for charge, release, AoE and counter | M3 scheduling authority, M5 damage |
| `scripts/domain/m4/casting/casting_timeline_resolver.gd` | MODIFY | Due Full/Last entries delegate to existing Lv40Cast.settle with authoritative M2 settlement | M4 release ordering, no double payment |
| `scripts/domain/m3/reaction/reaction_eligibility.gd` | MODIFY | R05/T05 tagged content checks with existing JIT resource and recipient validation | M3 manual reaction window |
| `scripts/domain/m3/reaction/reaction_queue_resolver.gd` | MODIFY | After actual M2 pay, execute approved R05 redirect+counter marker / T05 HP barrier | M2 pay-on-confirm, no free effects |
| `scripts/domain/m5/status/status_resolver.gd` | MODIFY | Versioned tick boundary `NEXT_PLAYER_PHASE` (default) or `ENEMY_PHASE_END`, status instance agreement | Single Status authority; Scorch ticks at enemy end |
| `scripts/domain/m5/damage/damage_pipeline_resolver.gd` | MODIFY | Lv40-only missing-element neutral 10000 bp fallback; unchanged non-Lv40 fail-closed | Content-scoped candidate policy |
| `scripts/domain/m5/lv40/lv40_domain_extension.gd` | MODIFY | Direct typed Status.tick and Status.validate postcondition | Atomicity, no duplicate status pipeline |
| `tests/test_lv40_content.gd` | MODIFY | Opt-in/version schema; real Scorch instance; enemy-end-only tick | Content and status boundary oracles |
| `tests/test_lv40_domain.gd` | MODIFY | Real SP hand→discard, spent-card reject, identical seeded replay hashes | M2 conservation, M5 replay |
| `tests/test_lv40_edges.gd` | MODIFY | No early Scorch tick; invalid trigger; Lv40 neutral vs legacy reject | Negative and compatibility boundaries |
| `docs/verification/PH4_LV40_DOMAIN_NOTE.md` | MODIFY | Exact wiring paths, evidence status, prior-GUI retry policy, gate plan | Reproducible engineering record |

No second combat state, RNG, damage calculator or reaction-payment authority was introduced. `pending_integration.patch` was **reviewed and translated to narrow exact edits**, not blindly applied as a standard git diff. Original content modules, provisional balance, GUI and P4.4 files were preserved.

## Contract

- Formal external API: `M5.apply(state, command, config)`; replay: `M5.replay(initial, tape, config)`.
- New content command: `PLAY_LV40_CARD` with `type, command_id, expected_event_seq, actor_id, card_instance_id, target_actor_id, casting_mode`, optional `combo_mode`; never accepts supplied costs, HP, skills or effect numbers.
- Lv40 gate: `m5_lv40_enabled=true`, matching `m5_lv40_content_version`, `m5_balance_authority=BALANCE_PROVISIONAL`. Existing M5 danger/terminal checks still precede the new dispatcher.
- M3 enemy execution: original scheduler/windows close through `RESOLVE_ENEMY_ATTACK_M5`; Lv40Boss reports trusted `timeline` and updated `core`. R05 defense carries `lv40_counter_actor_id` set only by a paid, confirmed reaction.
- M4 due release: `Lv40Cast.settle(core,cast,next_round,config,command_id)`; existing sorted due list governs lifecycle.
- Status: `Status.tick(core,next_round,config,command_id,trigger="NEXT_PLAYER_PHASE")`. Existing calls without selector retain original PlayerPhase semantics; explicit `ENEMY_PHASE_END` is used solely by Lv40 extension.
- Output event envelope: `event_seq,kind,command_id,source,details,phase,round`, with existing core event wrappers. Rejected command uses original state duplicate, empty events, unchanged RNG/event sequence.
- Candidate balance remains **BALANCE_PROVISIONAL** under docs26/27/29 candidate A; no 400-battle or human playtest approval.

## Tests / evidence

- Environment: GitHub connector only; no current Godot binary / local checkout. Source record mentions Godot `4.7.2.stable.official.ed1daf0bf` on the earlier operator machine, **not** verified in this receiving runtime.
- Executed current-turn Godot commands: **NONE**. Lv40 three suites attempt count **0** in this receiving session; no new logs, screenshots, runtime hash or CI run URL.
- Tests added without weakening existing oracles; `NOT_EXECUTED` must be reported, not PASS.
- **Pending commands on a local verified Godot 4.7.2 checkout**:
  ```bash
  godot --version
  godot --headless --path . --editor --import --quit
  for test in test_lv40_content test_lv40_domain test_lv40_edges; do
    godot --headless --path . --script "res://tests/${test}.gd" > "outputs/p4_logs/${test}_wiring_attempt1.log" 2>&1 || exit 1
  done
  ```
  Run all existing M1–M5.5 Domain suites, 100 fixed seed replay and four legacy smoke groups; preserve every raw log and exit code. Verify deterministic event/final hashes and error/atomicity paths. Do not assert parity from old 1,238/1,238 logs.
- Carried forward unchanged: P4.3 successful CI #38685051780; P4.4 local feedback 45/45, edges 80/80, 1238 Domain / 100 seeds / four legacy suites (PRE-WIRING), GUI input capture attempt 3 = **14/16 FAIL** (two PNG saves failed). P4.4 GUI allowed 3 attempts used; no fourth run without prior authorization.
- Master remains unchanged as required; branch workflow push filter excludes checkpoint, so **no new CI validation** occurred.

## Codex next actions (maximum five)

1. Fetch `handoff/p4-lv40-chat-20261015`, pin the actual full SHA; compare against input `977a289...`, preserve local/user dirty changes. **Do not re-apply the diff to an already updated branch.**
2. Review all 8 code paths and the unified diff from `LV40_DOMAIN_WIRING.patch`, especially `Status.tick`, Boss charge/release/intent retention, Action/Reaction JIT ordering and Last Spell release invariants. Use approved docs26/27/29, docs22 and `COMBAT_SPEC_INDEX.md`.
3. With Godot 4.7.2, run the three Lv40 runners + complete Domain regression + 100 seeds + four legacy suites on the modified branch; record each group's existing attempt counter, true failures, raw logs, exact seed/tape and final/event hashes. Do not weaken an assertion to get green.
4. Preserve the unresolved P4.4 GUI 14/16/attempt3 evidence; no additional GUI run without its specific user authorization; report any Lv40 Domain failures separately.
5. Only after applicable gates pass, update verification/RTM documents and obtain required approval for merge to master; P4.5 cannot be declared VERIFIED from this return alone.

## Risks / learning

- Major unresolved risk is **runtime correctness**: Code was statically reviewed against existing entrypoints but never parsed or executed under Godot here; any type/parse or API conflict must be treated as a genuine failure until tested.
- Rollback is scoped: revert only the Lv40 wiring/test/note commits on the checkpoint branch or apply their inverse; do not reset or force push user history.
- Architecture rationale: M5 is a transactional reducer, M3/M4/M2 enforce ordering and payments, and Lv40 modules supply content-specific policy only.
- Android / Kotlin analogy: this is like keeping a single `ViewModel.reduce(Action) -> State + Effect` transaction and calling domain use cases rather than letting Compose UI or animation callbacks charge MP / alter HP. The `event_seq` and command ID are optimistic concurrency/idempotency guards; seeded event + state hashes are replay determinism oracles.
- Source → code → test → evidence: mapping above is complete through **test source**, but **actual runtime evidence is still MISSING**.
