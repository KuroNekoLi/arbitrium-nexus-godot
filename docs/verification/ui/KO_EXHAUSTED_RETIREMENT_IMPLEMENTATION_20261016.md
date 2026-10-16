# Three-hero Incapacitated / Last Spell Field Retirement — 2026-10-16

**Status:** SOURCE IMPLEMENTED + HEADLESS VERIFIED + TRUE-RENDER VERIFIED (visual design iteration, not final art sign-off)

## Product decision

For the current three-active-hero prototype without reserves:
- `INCAPACITATED`: HP=0, remains on the battlefield, downed CG posture, roster HP=0 and an incapacitation status, no Last Spell retirement cross. Existing Domain Revive may restore HP/action eligibility per its rules.
- Successful Last Spell release: `EXHAUSTED` and **field retirement**. No reserve replacement in this release; only the other two actors are on the field. The retired actor's Domain identity, hand zones and once-per-battle history remain for replay. Roster keeps the actor as a greyscale/darkened record with a visible X mark. Battle CG is hidden; not killed/deleted.
- A Last Spell that is invalidated due to HP0 **before release** is NOT a successful release; it does not receive the field retirement marker.
- Future five-member roster, auto-substitution, swap AP, and VC were NOT implemented.

## Versioned rollout and compatibility

`config["last_spell_retirement_v1"]` is true in `BattleScreen` **only for `encounter_profile == "lv40_playable"`**. The legacy fixture profile deliberately retains the historical M4/M5 event/state contract because existing fixed-seed deterministic golden tapes are sensitive to changes in emitted events and state hashes.

On an opted-in successful release, `LastSpell.settle(..., true)` sets the actor's existing `status=EXHAUSTED` and `core.battle.retired_from_field_by_actor[actor_id]=true`; `ActorExhausted` marks `still_targetable=false` and `retired_from_field=true`. On the legacy default argument, the old event/state payload stays exactly the same. This distinction is intentional, not an assertion that the old fixture is now using the new rules.

Boss AI selection (M5.3 and Lv40), Lv40 enemy-hit resolution, M5.1 direct damage validation, paid M5 status targeting, HP heal/revive and Lv40 card target preview block targeting **retired** allies where applicable. A battle that has no legal remaining front-line actor is outside the currently approved outcome policy; do not invent replacement, revival, all-retired defeat, VC or swap effects.

Presentation remains read-only: `BattleActor.project_conditions` renders an incapacitated actor tilted/tinted in place and hides an exhausted one; `HeroRosterItem` renders HP0 normally with incapacitation status, versus a darkened portrait/X mark for exhausted. `BattleScreen` avoids keeping a retired actor's active card hand selected and forbids selection of a truly retired actor. Core Domain values remain untouched by `present`.

No replacement character CG was generated; the existing atlas sprites are reused with pose/tint changes. Future higher-quality downed poses require dedicated licensed/approved artwork.

## Actual evidence

Source implementation commits begin at `58de60e7` with corrections for replay/version compatibility. The **verified production source snapshot** is `5dd3f9d1159831da3d89828854a3e862e695f9e1` (before a later screenshot-only change `bd0f5b27cd103ec1fe4d4141344a22dae998e756`).

- [Three-hero focused Godot 4.7.2 CI #38852570843](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38852570843): **29/29** `RETIREMENT_REPORT` (Domain Last Spell successful settlement / field marker / exclusion, Boss target lists, incapacitated CG pose, retirement X roster, no presentation Domain mutation), existing V1 Component **24/24**, P4 HUD **36/36**. [Raw logs](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38852570843/artifacts/12025003638).
- [Existing CI Fast #38852570745](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38852570745): both Fast + P4-contract jobs **success**, including unchanged older fixed-seed deterministic Golden Replay. [CI logs](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38852570745/artifacts/12026017812).
- [Real Godot X11/Mesa capture #38852570958](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38852570958): original V2.3 screenshots 30/30, Boss Break screenshot 20/20, **4 genuine KO/retired state captures 18/18**, including `ret_ko_1280_zh`, `ret_ko_1920_en`, `ret_exhausted_1280_zh`, `ret_exhausted_1920_en`. [Original PNGs and manifests](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38852570958/artifacts/12025238345).
- [Screenshot preview revision #38852852591](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38852852591): rendered KO + Exhausted thumbnails emitted as JPEG base64 in successful action logs; **20/20** including thumbnails; original PNGs and manifest [artifact 12026260520](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38852852591/artifacts/12026260520).

The captured KO/retirement states are **read-only isolated render fixtures** built from actual Domain settlement, not a claim of a player-performed full playable Lv40 battle. The latter should be an additional final user playtest/QA gate when the playable encounter is ready.

## Exclusions and unresolved decisions

- No five-member team or reserve auto-substitution implementation.
- No VC, AP-cost manual swap, or retreat animation/transition production.
- No overall battle outcome change for `all_exhausted` / no front-line survivors while enemy still alive; that remains a distinct unanswered design case in phase-boundary logic.
- No historical P4.4 GUI 14/16 retry or claim that problem has disappeared. The successful P4 headless regression is a separate gate.
- New darkened/X status is a **functional presentation**, not final reference-image-level character/roster CG quality. The actual 1280/1920 PNGs require visual approval.

## Developer learning: Why model field retirement separately?

`INCAPACITATED` is a life-cycle status (HP=0, recoverable by actual Revive). `EXHAUSTED` is persistent Last Spell action incapacity. `retired_from_field_by_actor` is a battle-location/target-eligibility fact, not an instruction to delete character state. That separation prevents accidental healing/attacking of a visually absent character and keeps per-character hands, history, RNG and replay traceable. The versioned content flag prevents rewriting the meaning of historical replay tapes silently.
