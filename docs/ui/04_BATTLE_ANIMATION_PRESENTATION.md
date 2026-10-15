# 04 — Godot 戰鬥動畫與 2D／2.5D 表現層設計

> **DESIGN ONLY / NOT IMPLEMENTED**。本規劃只定義 presentation 工程方法，不批准任何未定數值、傷害、回合時序或美術造型。現有實作資產先保留；任何出場演出都不得更改 headless Domain 的結果與可重播性。

## 1. 一張概念圖能做到什麼

- 戰鬥概念圖可提供鏡頭、構圖、色彩、角色／Boss 尺寸關係、戰場透視、卡牌和 HUD 欄位參考。
- **不能**無損得到背景、角色、Boss、卡圖、法陣、UI框的獨立可動畫圖層；單張圖裁出的角色通常帶有背景、錯誤透明區、僅一個姿勢。
- 擁有單張透明角色圖即可做 **Tween/AnimationPlayer** 前衝、受擊閃光、抖動、輕量呼吸／漂浮；真正的揮劍手部動作、連續法陣姿態／Boss 部件破壞，最好有多影格或部件分層。
- AI 可生成獨立角色／Boss 圖與動畫影格，但**需要**角色特徵鎖定、透明 alpha、朝向、anchor/pivot 和 frame-consistency QA；不可保證一張截圖自動變商業品質動作。
- 初期動畫優先使用 repo 已存在的 `kleya_atlas`、`nova_atlas`、`yora_atlas` 與現成 Particle Pack；先盤點原始尺寸及使用權。

## 2. Presentation actor 接口（提案）

```text
BattleActor.tscn (Node2D; visual only)
├─ BodyPivot (Node2D)          # 世界位置，動畫位移不改 Domain target/range
│  ├─ Sprite (AnimatedSprite2D or composite parts)
│  ├─ AnimationPlayer
│  ├─ OptionalSkeleton2D      # 僅在有分層素材時啟用
│  ├─ CastAnchor (Marker2D)
│  ├─ WeaponImpactAnchor (Marker2D)
│  └─ StatusVFXAnchor (Marker2D)
├─ VFXContainer (Node2D)
└─ PresentationState (visual flags / animation queue)
```

建議公開方法（示意，不需現在新增）：
- `configure(actor_id, appearance_resource, actor_side)`
- `play_idle()`, `play_attack(visual_action_profile, event_ref)`
- `play_cast_start()`, `play_cast_loop()`, `play_cast_release()`
- `play_hit(hit_cue)`, `play_guard()`, `play_break()`, `play_incapacitated()`
- `set_visible_status_icons(status_projection)`, `cancel_visuals(reason)`
- `animation_finished(action_id)` 只通知 presentation，不觸發 DamageResolver 再執行。

所有 action_id、actor_id 必須來自 domain 事件或其安全 projection；Animation profile 只選擇畫法，不能變更驗證結果。

## 3. 三種視覺技術路線與決策點

| 路線 | 優點 | 代價 | 建議 |
|---|---|---|---|
| **A — 純 Node2D + Sprite2D / AnimatedSprite2D** | 對已存在的 2D atlas/PNG 最兼容、整合成本低、較易與 UI 分層 | 透視／立體光影效果有限 | **P0 開發 spike 優先** |
| B — Node3D + Sprite3D billboard / AnimatedSprite3D | 可使用 3D 鏡頭、深度、場景物件 | 素材朝向、遮擋、renderer/alpha 與輸入坐標更複雜 | 需要真實需求與性能比較 |
| C — Hybrid SubViewport（2D＋3D） | 可在同一 HUD 下混合深度、特殊空間 VFX | Input mapping、texture sampling、resize／同步成本高 | 最後選，必須有 ADR |

目前 `project.godot` 是 Compatibility renderer、1280×720；任何 Glow/Shader/Particles 視覺設計均需先確認在這個 renderer 的實際效果，不憑高品質概念圖假設 Forward+ 功能可用。P1 骨架不新增自由走位或 AP 走位命令；鏡頭往前推的視覺位移不是 Domain Position 變化。

## 4. AnimationCue 與事件對應

```text
Domain Command → validated Domain state/event timeline
                                ↓
Presentation Adapter maps Events to immutable Cue list
                                ↓
Animation Queue (visual-only, cancellable, skippable)
  - actor pose / position tween
  - VFX emit / shader flash / hit numbers
  - camera emphasis / audio
  - UI resource/status updates from authoritative snapshot
                                ↓
Animation finished OR skipped → ready for next visual event
```

**重要區分**：
- Domain 的 `HitResolved`／`DamageApplied` 結果已確定；UI 可讓傷害數字在動畫 Impact 上跳出，但不能在 Impact 才扣 Domain HP。若為了演出延遲顯示 UI 數字，必須保留權威狀態與觀察一致性（例如 display snapshot 漸變），並能在 Skip 時立即追到正確值。
- 每個 Cue 綁 `battle_id + event_seq + action_id` 去重；重播截圖可重跑動畫而不重扣資源。
- 取消動畫／Skip VFX、FPS 掉到 10 或使用者跳過所有鏡頭，不應影響 RNG、狀態 Hash、勝敗或持續時間。
- 如果 domain 先宣告 Boss 行動，但 Reaction 成功中斷，畫面只可播蓄力→失敗／中斷，不得因原本設計好的 Boss 攻擊動畫而傷害玩家。
- 如果敵方攻擊合法轉向 Protect，真正受擊的 `recipient_id` 由 Domain 事件決定，不能 UI 自行決定誰幫誰擋。

## 5. 共用動畫動作庫與最小演出

| Animation ID | Scene 動作 | 必須事件／視覺差異 |
|---|---|---|
| idle | 呼吸、布料微動、粒子 | 無需 Domain tick；可重複 |
| selected | 角色輪廓發光、選取光圈 | 純 UI focus，不扣資源 |
| attack_prepare | 抬武器與微停頓 | 待執行的合法行動 |
| attack_lunge | 前衝到視覺攻擊位置 | 不改 Domain range tag |
| attack_impact | 劍光、火花、命中或 miss | Hit outcome 真實事件 |
| attack_return | 返回 ActorSlot 原點 | 必須可恢復同一位置 |
| cast_start | 出現法陣／聚光 | 成功提交施法 |
| casting_loop | 角色專注，魔法回圈 VFX | CastingInstance 存續 |
| cast_release | 光束／術式釋放 | Domain 到期且有效 |
| casting_interrupted | 法陣破碎、聚光熄滅 | Domain CastingInterrupted，不自定退款 |
| guard/protect | 防禦姿勢、移動護援視覺 | 目標／保護者由 Domain 决定 |
| hit/block | 閃白／受擊後仰／Shield 閃動 | 屏障與 HP 扣費各由 event |
| break/exposed | Boss 破綻、失衡姿態、明確提示 | Domain 正式 Break / Exposed |
| combo_finisher | Setup→Finisher 連攜連段與提示 | 只當 ComboOpportunity 合法提交 |
| last_spell_start | 明顯且特殊的不可逆完整詠唱 | Domain 已接受使用 |
| last_spell_destabilized | 失衡漣漪／詠唱變暗 | 只顯示延後/削弱，不自行取消 |
| last_spell_release | 專屬大招＋高對比結果提示 | 成功釋放後角色 Exhausted |
| last_spell_invalidated | 法陣崩解、特定失效通知 | HP0 未釋放強制失效，不可仍播大招 |
| incapacitated/exhausted | 不同姿勢、不同 icon/tooltip | 不得把兩者合成「死亡」 |

動畫時間（秒）為**視覺暫定**，不是回合時間，也不是 Reaction 超時。聲音可用 Kenney 音效；正式音效與每名角色的命名資料仍需獨立審核。

## 6. 第一個 Vertical Slice：玩家普通攻擊 → Boss 反應

**前置：** 一位合法玩家角色（角色來源經 Actor ID 核對）、一個既有 Boss、合法指令可由 Domain 承接、兩者有可用 idle 動作，排除錯誤素材。

**視覺順序：**
1. 玩家點 `HeroRosterItem`（切 focus 不扣費）；
2. 點基本攻擊或選符合資格卡（展示 legal cost/target preview）；
3. Submit → Domain 验證完成，生成 action/event sequence；
4. 角色 `attack_prepare`、`attack_lunge`、`attack_impact`，讀取正式 `hit/damage/break` 事件播放正確效果；
5. `attack_return` 回到正確 ActorSlot；HUD 顯示權威資源，剩餘合法 AP 可讓同人或他人繼續選；
6. 後續 Boss 於 Enemy Phase 公開 intent、Reaction Window 開啟；玩家佇列或略過，確認後事件決定 Boss 真正動作；
7. Reaction interrupt 成功時 Boss 播中斷，未中斷才播放真正攻擊／被保護目標受傷。

**拒絕路徑：** 卡牌不在手、非法 target、資源不足、角色 Concentrating／Exhausted、已結束 Window，皆只能顯示合法錯誤，不播出像成功的傷害動畫。

## 7. Asset／技術製作方案

- AnimationPlayer：補間 BodyPivot 的局部位置／旋轉／scale、可見性，適合從單張透明圖開始做簡單演出。
- AnimatedSprite2D：已有連續逐格或 Sprite Sheet 時優先；每組動畫按角色 Appearance 分配 SpriteFrames。
- Skeleton2D：只有清楚分層（頭、身、前臂、武器、衣裝等）才考慮；勿把概念圖裁成人體關節而不審核遮擋／扭曲。
- Shader/Particles：剣光／魔法／Boss core、hit flash、dissolve、屏障；需要 fallback 用簡單 Tween 代替高成本 shader。
- Animation Libraries：共用 event 種類和時間線規約，Animation 資產按 actor_id、variant、weapon、spell profile 指定；角色獨特動作不得寫死在共用 UI Scene。
- SFX：聲音事件由 Presenter 觸發，使用來源／授權已核可素材，避免每張卡重複掛獨立 SoundStreamPlayer。

## 8. 針對 16:9 與可讀性的攝影機契約

- HUD 安全區優先，Boss 特效不能長期遮住 intent 或卡牌選擇；高光閃爍必須可以降級或關閉。
- 戰場 3 個 ActorSlot 與 BossSlot 的位置是演出座標，並非玩家可走的格子。
- Camera shake 僅視覺效果，需可調強度／關閉，不應造成 UI 字晃動；如果 HUD 使用 `CanvasLayer`，相機 shake 只套 World。
- 卡牌本體位於 bottom-safe 內，選中 hover 放大時不被 World VFX 蓋住；Boss 範圍攻擊須清楚標示受影響角色而非僅依火光顏色。
- 首次 visual gate 需錄製 1280×720 與 1920×1080（若二者實際支援），確認 Sprite 清晰、無嚴重透明穿插、可操作交互不被 VFX 搶 focus。

## 9. Animation QA Test Matrix（規劃案例）

| Case | 操作 | 必須觀察 |
|---|---|---|
| ANIM-01 | 合法普通攻擊 | 一次 Domain command、一組 action cue、回原點 |
| ANIM-02 | 非法成本攻擊 | 不播放成功 AttackImpact、不扣費 |
| ANIM-03 | Enemy Intent→Reaction Pass | 無計時器、手動 Pass 後才演出 |
| ANIM-04 | 中斷 Boss 正在執行的動作 | 播阻止／取消動畫，不播傷害 |
| ANIM-05 | Protect 有效 | 真正接收者與イベント顯示一致 |
| ANIM-06 | Full Chant 延遲結算 | 專注 loop + 到期 release，非即時傷害 |
| ANIM-07 | Last Spell 施法者 HP0 | 強制失效、絕不播成功釋放 |
| ANIM-08 | Last Spell 成功 | Exhaused 專屬姿勢／禁止一般動作 |
| ANIM-09 | 選角切換／卡牌 Hover | 不產生任何 Domain command |
| ANIM-10 | 跳過動畫、低 FPS、重播 | Domain event hash 與 final state hash 一致 |

## 10. 官方文件與跨組技能

- Godot 動畫：https://docs.godotengine.org/en/stable/tutorials/animation/introduction.html
- Godot 2D 逐格動畫：https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html
- 本專案既有 Skills：`.codex/skills/godot-2-5d-rendering-engineer/`、`godot-game-asset-pipeline/`、`godot-card-rpg-uiux-engineer/`。由 orchestrator 分工，先讀各 Skill `references/`。
- `docs/combat/05_DUAL_CASTING_AND_INTERRUPTION.md`、`07_REACTIONS_PROTECTION.md`、`08_LAST_SPELL_EXHAUSTED.md`、`12_ENGINE_ARCHITECTURE_EVENTS.md`。

正式施工前必須使用指定 Godot 4.7.2.stable 在實際目標 renderer 上驗證上述提案；本文件不提供任何已執行測試證據。
