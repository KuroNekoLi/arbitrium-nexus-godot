# Spell Casting Visual Foundation (Godot 4.7.2)

**Implementation branch:** \`feature/spell-projectile-visuals-20261016\` (based on master \`50bf7b19b2f9c3d66c1a8cd267bd20ef7f56b4cd\`). No changes to Domain costs, damage, targeting, casting timing or Replay.

## Problem / proposal

Old \`BattleAnimationDirector\` treated damage as a shared hit sequence with a burst and no travelling magic sprite; its cue-based magic flag was not a reliable style classifier for \`PLAY_LV40_CARD\`. The visual goal is **stationary caster → visible magic emission → projectile travels toward the accepted recipient → impact**, while physical sword skills keep the original dash. Full Chant initiation never fires a projectile early: release is driven by later authoritative events. Last Spell release is recognized by \`spell_id\` on \`LastSpellReleased\`.

The current [Kenney Particle Pack (CC0)](https://github.com/Calinou/kenney-particle-pack) already exists at \`addons/kenney_particle_pack\`; this uses its \`fire_01\`, \`flare_01\`, \`magic_01\`, \`star_02\`, \`circle_04\` textures. No new plugin, external binary or license is required. Styles are visual profiles only; \`CanvasItemMaterial.BLEND_MODE_ADD\` is used for a short-lived projectile texture.

## Roster and full 12-card actions per character

Authoritative names, exact card lists and semantics: \`resources/combat/rosters/lv40_party_v0_3.json\`, \`resources/ui/lv40_strings.csv\`, \`scripts/domain/m5/lv40/lv40_content.gd\`.

### Shared UNIVERSAL cards (all three actors)

| ID | Name (zh_TW) | Visual | Behavior |
|---|---|---|---|
| U01 | 奧術彈 | ARCANE_BOLT | Stationary → indigo projectile → enemy |
| U02 | 魔力屏障 | BARRIER | Stationary → friendly shield pulse |
| U03 | 專注護符 | WARD | Stationary → casting/protection pulse |
| U04 | 魔力調律 | AURA | Stationary → ally glow |
| U05 | 初階治癒術 | HEAL | Stationary → ally heal glow |

### A — 朝霧蓮 (Swordsman)

| ID | Name | Visual | Behavior |
|---|---|---|---|
| R01 | 破勢斬 | MELEE | Dash, blade strike, return |
| R02 | 連環擊 | MELEE | Dash + existing multi-hit receipts |
| R03 | 刺隙一閃 | MELEE | Dash and strike |
| R05 | 援護反擊 | PARRY | Reserved for Reaction flow, no fabricated projectile |
| R06 | 蒼月斬 | MELEE | Dash and slash (visual only; no extra damage) |
| R07 | 戰隙誘引 | MELEE | Dash, physical contact |
| R08 | 守護誓約 | BARRIER | Stationary ally shield pulse |
| LS_REN_SWORD_V1 | 蓮的終極法術 | MELEE | Physical release / no fireball |

### B — 九條朱音 (Burst mage)

| ID | Name | Visual | Behavior |
|---|---|---|---|
| A01 | 燐火彈 | FIREBALL | Stationary → orange fireball → enemy |
| A02 | 熾焰潮 | FIRE_WAVE | Stationary → fire projectile to **single** target; no new AoE |
| A03 | 凝火 | AURA | Stationary self buff |
| A04 | 灼熱束 | FIRE_BEAM | Stationary → luminous fire beam sprite to enemy |
| A05 | 熾脈干擾 | DISRUPT | Stationary disruption glow at legal target |
| A06 | 星墜槍 | FIRE_LANCE | Stationary → fiery lance sprite |
| A07 | 紅蓮餘燼 | FIREBALL | Stationary → ember-like projectile |
| LS_AKANE_MAGE_V1 | 朱音的終極法術 | FIRE_LANCE | Projectile on **actual** successful release, not commitment |

### C — 白石紬 (Healer/support)

| ID | Name | Visual | Behavior |
|---|---|---|---|
| T01 | 治癒術 | HEAL | Stationary → heal at ally |
| T03 | 祝福領域 | PARTY_HEAL | Stationary → glowing allied field |
| T04 | 守護之光 | BARRIER | Stationary → ally shield |
| T05 | 祈光應答 | BARRIER | Reaction visual reserved |
| T06 | 生命織補 | HEAL | Stationary → healing ally pulse |
| T09 | 光羽彈 | LIGHT_BOLT | Stationary → light projectile → enemy |
| T10 | 祈光脈衝 | LIGHT_BOLT | Stationary → light projectile + existing Domain heal |
| LS_TSUMUGI_HEAL_V1 | 紬的終極法術 | PARTY_HEAL | All allied field on genuine release |

**Note:** Currently only 3 front-line allies and one Boss. Presentation registration is preparatory for multi-target; no fabricated multi-enemy hit resolution or actor layout.

## Ownership and isolation

- \`SpellAnimationCatalog\` is a static, typed visual lookup. Unknown ids map to \`NONE\`, not presumed magic.
- \`BattleScreen._on_resolved\` attaches \`_visual_card_id\` to a **copy** of an accepted command for the director only; tape, controller, command validation and snapshot remain untouched.
- \`BattleAnimationDirector\` uses \`CastingReleased\` / \`LastSpellReleased\` \`spell_id\` for delayed release, never the currently selected card.
- \`BattleActor.play_spell_cast()\` plays a stationary glow gesture without calling \`play_attack\`.
- \`BattleEffects.launch_projectile()\` spawns and frees a Kenney-textured Godot \`Sprite2D\` with additive effect; no collision. Domain \`DamageTrace\` decides whether and to whom damage applies. UI flight waits before showing its previously accepted receipt; it never blocks Domain settlement.
- VFX skip/reduced-motion retains old behavior: skip cleans effects and cancels waits; reduced-motion has no traveling sprites and retains accepted damage presentation.

## Test acceptance

- Pure registry count, cross-class consistency, delayed release overriding active UI card, special ultimate handling.
- Godot headless visual fixture: B fireball keeps position, a live \`SpellProjectile\` exists mid-flight, visual nodes are removed afterward, A physical strike still moves/returns, skip cancels, reduced motion does not spawn flight, controller snapshot hash stays untouched.
- Existing P4 integration and Lv40 playable headless + golden Replay gates.
- Screenshot/video is required before final high-fidelity art sign-off. **This pass delivers reusable basic VFX, not a production-grade choreographed multi-frame fireball animation.**


## Verified implementation (2026-10-16)

**Implementation source snapshot:** \`6ec5f5166f4426ad9b616e5f37e0a37c00c7d3fa\` (the prior commits introduced VFX, then corrected Godot deferred deletion, draining pending SceneTreeTimers, and the reserved identifier in screenshot QA). The last two changes are scoped to QA and cleanup; no battle rules were edited.

[GitHub Actions spell visuals #38880689776](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38880689776) — **completed/success**, official SHA512-verified Godot 4.7.2:
- \`SPELL_VISUAL_REPORT executed=46 passed=46 failed=0\`
- \`P4_3_REPORT executed=31 passed=31 failed=0\`
- \`P4_LV40_PLAYABLE_REPORT executed=32 passed=32 failed=0\`
- \`V3_MERGE_REPORT executed=90 passed=90 failed=0\`
- Real X11/Godot 4.7.2 compatibility render: \`SPELL_RENDER_REPORT executed=8 passed=8 failed=0\`. The 1280×720 \`akane_fireball_in_flight.png\` and \`akane_fireball_thumb.jpg\` were written from the real Godot viewport, verified, and uploaded in [artifact 12037815792](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38880689776/artifacts/12037815792). The screenshot is a **VISUAL-ONLY TEST FIXTURE** that explicitly sends a single synthetic DamageTrace to isolate the projectile animation; it is not a claim of a player-triggered full battle.
- Strict import/CI logs: 0 errors, 0 object leaks. X11-only unsupported VSync warning is reported and accepted by the existing strict log classifier; no Domain/replay behavior was altered.

### Not yet complete

- This first milestone uses basic Kenney sprite flight/pulses; individual animation choreography and hand/staff pose CG are not finished. Specifically \`FIRE_WAVE\`, \`FIRE_BEAM\`, \`FIRE_LANCE\` currently share a common short-lived sprite projectile approach with different catalog texture/tint instead of bespoke multi-frame effects.
- Presentation visual coverage for reaction-only R05/T05 is registered but not fully animated.
- No claim of high-fidelity cinematic acceptance until visual review of original PNG or a video recorded from true card activation and delayed Full Chant resolution.
