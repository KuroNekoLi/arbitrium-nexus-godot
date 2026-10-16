# 09 — Combo System：標籤、Opportunity、UI提示與確認

> **Documentation status · 2026-10-15 — APPROVED_DETAIL + EXTENSION_UNVERIFIED**：M5.3 已驗證兩名不同角色、兩張真的 M2 付費 SP、額外 Combo AP=0；完整詠唱／Last Spell 共鳴及各卡數值屬內容未驗證。 現行導航：[Combat Spec Index](COMBAT_SPEC_INDEX.md)；缺口：[Open Issues](COMBAT_OPEN_ISSUES.md)。**Godot Domain M1～M5.5：1,238/1,238 通過；100 場固定 Seed 的完整戰鬥與 Replay 已驗證（[Master CI #38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741)）。Scene／真人可玩／正式平衡仍未驗證。** 以下舊段落保留歷史脈絡，不是新測試或新核准。


## 1. 已批准玩法

Combo 系統獨立於普通卡池，**沒有必須額外抽取的「連攜卡」**。特定卡牌可經由角色、tag、目標狀態、出牌順序產生 `ComboOpportunity`，符合條件時 UI 顯示「可連攜」，玩家選普通出牌或連攜出牌，成功時播放合作演出並結算。兩名不同角色才構成初版雙人連攜；專屬連攜可另外要求 `character_id/variant_id`。一般雙人連攜**額外AP=0**，參與的技能卡原本 AP/MP 照常扣。

## 2. 合格條件（示例）

克蕾雅使用帶 `BREAK` / `SLASH` 標籤的卡對Boss產生`EXPOSED`，此時尤拉手牌有 `FIRE` 且標示 `INSTANT_FINISHER` 的卡。UI高亮尤拉+火球。使用火球時可選普通破棄詠唱（例如18傷）或星焰劍舞連攜（卡原效果18 +連攜12傷、8 Break）。**不是**諾瓦只出Expose就免費讓另外兩名角色打30傷；Combo必须在第二名角色真正執行符合條件的卡牌時結算。

完整詠唱不應在「尚未生效」時直接觸發已命中的瞬發攻擊連攜；應走 `CastingCombo`：其他隊友對已在戰場的 CastingInstance 提供FocusWard/穩定度/效果強化，施法者不再動作。Last Spell共鳴同此模式、不得瞬發。

## 3. ComboOpportunity 狀態機

`NONE → OFFERED (when setup resolves) → READY (eligible card/participant exists) → CONSUMED (user confirms actual finisher) / EXPIRED (timeout or invalid state)`。Opportunity攜帶 `combo_id, source_actor_id, target_id, allowed_partner_tags, allowed_card_tags, expires_at, consumed, created_event_id`。同時多機會的優先顯示/衝突取捨仍待決。

**建議第一版（PROVISIONAL）**：每玩家回合至多發動一次雙人連攜；機會在本玩家階段結束清空；若隊友被打斷／Exhausted／所需目標已消失則即時失效。需要透過卡牌抽取／出牌流測試其頻率。

## 4. UI設計規約

- 先展示潛在可能（卡牌被選中時：可能產生 EXPOSED → 潛在 FIRE 連攜）。
- 實際建立Opportunity後，高亮符合資格角色頭像和手牌；不遮擋Boss意圖、AP。
- 點選合格 finisher 時，在操作卡片內比較普通 vs 連攜的傷害、Break、MP/AP與耗用機會；需玩家確認，不自動發動。
- 結算後明示「由哪兩名角色／哪兩張卡／哪個狀態」觸發，利於學習及debug。
- 未滿足條件的連攜不可點擊，提示具體未滿足項（如錯誤施法模式）。

## 5. 通用／專屬連攜

`Generic`: 兩名不同角色、技能類型/標籤、戰場狀態即可。`Exclusive`: 額外角色故事身份或戰鬥Variant、或指定動作條件，具有專屬演出；但仍使用相同引擎API。R～UR都可以憑標籤參與，稀有卡不得壟斷基本連攜資格。三人連攜是未來擴充（不納MVP）。

## 6. 非純傷害設計

三類首批實作：`OFFENSE`（傷害/Break）、`DEFENSE`（Barrier/Focus Ward）、`CASTING`（穩定度/共鳴/可控效果）；未來可新增干擾與控制。基本 Combo 應讓玩家在不同戰況做出真正的選擇，而非無條件附加暴擊。

## 7. 測試

- setup成功但沒有eligible finisher→不觸發、不扣連攜資源。
- 同一人自己出兩張不得當雙人Combo（除非未來另定義單人流派）。
- 合法第二張卡支付原AP/MP一次，Combo bonus額外AP必定0；不得多扣。
- 玩家選「普通施放」不消耗ComboOpportunity，是否立刻失效依機會期限（TBD）。
- 沒有足夠AP/MP不能用finisher；Concentration角色不能自行出第二張。
- Opportunity被消耗只能生效一次，另有時限／回合次數限制。
- 單張高稀有卡的倍率加成不得無限與共鳴相乘。


---

## 8. Phase 1 防禦型連攜與 Reactive SP 邊界

**APPROVED**：基本 Guard/Protect 不憑空觸發反擊、Combo、Break 傷害或多餘護盾。特殊 Reaction SP 才可以在卡片明示條件下提供這些戰術效果；但**此階段沒有批准任何具體防禦SP卡面、成本與防禦型Combo配方**。本章原有 Combo 核心（真正雙角色/合格技能卡、0額外 AP）仍有效。

未來若加入反應式防禦Combo，必須在 `ComboOpportunity` 記錄 setup 來源與有效期限，並使實際獨立 Reaction SP 使用/結算滿足不同角色、所需卡牌實例、合法觸發與費用。不可把基本Protect「被按過」當作已施放第二張真正 SP，也不得規避「同一角色在同一窗口至多一次 Reaction」限制。若特殊SP因 P1-D16 被跳過，不能仍無條件獲得其連攜效果或棄牌觸發。

**TBD**：Reaction階段是否允許專屬防禦型 Combo、使用何種卡牌標籤、是否需要主動玩家回合 setup、按敵方行動開窗口時機、Combo是否附加RP費用、Boss攻擊被反制取消後Combo結算次序。不得以本文中的示範連攜招式當作已獲核准的卡牌資料。
