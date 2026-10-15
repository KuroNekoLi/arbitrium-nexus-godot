# 11 — 傷害、命中、閃避、狀態與死亡（決策待補）

> **Documentation status · 2026-10-15 — APPROVED_DETAIL + HISTORICAL_D20**：本章早期 d20/Nat1/Nat20、死亡和傷害全待決說法已由 P2-D01～16、20/21、M5.1～M5.4 headless 部分覆寫。正式數值平衡及混合 AoE 邊界仍未完整核准。 現行導航：[Combat Spec Index](COMBAT_SPEC_INDEX.md)；缺口：[Open Issues](COMBAT_OPEN_ISSUES.md)。**Godot Domain M1～M5.5：1,238/1,238 通過；100 場固定 Seed 的完整戰鬥與 Replay 已驗證（[Master CI #38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741)）。Scene／真人可玩／正式平衡仍未驗證。** 以下舊段落保留歷史脈絡，不是新測試或新核准。



> 本章大多屬 **TBD**。本章的用途是避免Agent誤將模擬器固定傷害、必中或單一目標當作正式玩法。

> **重要修訂：本章部分內容已被 Phase 2 已核准決策取代。** 以 `16_PHASE2_APPROVED_DECISIONS_WIP.md` 為準：混合型分類命中、百分比、一般 5%～95%、Accuracy/Evasion 線性差值、混合型 HP 傷害模型、小幅浮動、混合型暴擊均已 APPROVED；**d20/Nat1/Nat20 僅是舊史料，不再是現行命中系統。** 暴擊數值／倍率 P2-D08、元素、狀態、死亡及結算順序仍 TBD；其餘詳見 `17_PHASE2_HANDOFF_AND_OPEN_QUESTIONS.md`。

## 1. 歷史規格

原 `COMBAT_SYSTEM.md` 提到 `Attack Roll = d20 + Attack Bonus` 對抗Defense、Nat1自動失敗、Nat20特殊成功，初期命中率目標60–75%。**它是歷史Canon方向，卻尚未與最新共享AP/牌組技能的命中、閃避、魔法自動命中設計整合。** 使用者已提出角色基礎閃避率因Variant不同，但未指定公式。LEGACY-Q09 必須核准。

## 2. 必須分離的事件

`HitCheck`（命中/閃避）→ `DamageCompute`（物理/魔法和暴擊）→ `BarrierAbsorb`（HP盾）→ `ApplyHP`→ `ApplyOnHit/OnDamage`（燃燒/中毒/干擾）→ `CheckDowned`；若能力是「必定造成干擾，即使命中失敗」，應由卡牌Effect明文定義，不得誤用通用OnHit。

另一路獨立：`CastingDisruption` → `FocusWardAbsorb` → `CastingStabilityReduce` → `InterruptOrDestabilize`；它不必等於HP傷害，除非技能明文關聯。

## 3. 狀態效果資料

候選結構 `{status_instance_id, source_id, target_id, status_id, stacks, remaining_ticks, tick_trigger, dispel_tags, modifier_layers, expires_on}`。燃燒/冰凍/中毒/沉默/暈眩等目前尚未核准精確持續與優先級，不得擅自賦予每輪固定扣血等規則。

## 4. Exhausted 與 Incapacitated

- `EXHAUSTED`：因Last Spell成功結算不可再發起任何行動；不是死亡。
- `INCAPACITATED`：HP歸零後的失能或死亡狀態，復活、遺失手牌、MP和牌庫的處理**TBD**。
- Exhausted能否成為敵人新目標、受範圍傷害、被治療、阻擋技能，以及全隊全Exhausted時是否敗北均需明文定義，不能從單一模擬事件推定。

## 5. 勝敗與戰鬥終止

至少須定義：最後敵人HP歸零→勝利；所有角色不可行動/死亡→失敗或戰鬥其他處理；雙方同時歸零/Last Spell同時結算的優先順序；Boss開始或結束演出期間判定結果。這些尚未全部由使用者批准；應阻擋正式Boss戰實作直到D10完成。

## 6. 單位、位置與目標

原歷史GDD偏向Zone/Relative Range（Close/Near/Far），但實際Position、攻擊距離與位移成本未定。卡牌必須有 target policy（自我/友軍/敵單/敵全/當前Casting）；AI/玩家UI必須共用合法性校驗，不能讓 Boss 隨機攻擊預先未鎖定目標。

## 7. 測試矩陣準備

給出 d20 vs百分比閃避候選、必中/免疫、零傷害與 shield、破防是否和HP傷害分離、暈眩中詠唱、DoT同回合死亡、Exhausted目標/勝負，逐項添加ADR後轉正式 acceptance test。


---

## 8. Phase 1 傷害重導向與防禦分層（APPROVED 範圍）

### 8.1 基本傷害計算合約

對符合條件的攻擊，實際傷害承受者的防禦/抗性先參與常規HP傷害計算；若他使用合法基本Guard，再於此結果套**固定**比例減傷。此固定比例如何決定以及是乘法或定額? **已選固定比例**；具體值40%僅示例，傷害取整規則尚未核准。若遇 Protect，先將單體攻擊的承受者轉為守護者，再按**守護者自身**防禦/抗性重算，Protect不另外減傷。Guard不會把 `Casting Stability` 當HP來打折。

建議型式（不代表已核准所有運算先後）：

```text
attack = ResolveDeclaredEnemyAttack()
if attack.is_single_target and attack.protectable and ProtectExecuted:
    damage_recipient = protector     # 已核准的承受者變更
else:
    damage_recipient = original_target
base_hp_damage = ComputeUsingDefenses(damage_recipient.stats, attack) # 細公式 TBD
if eligible_self_guard_executed_for(damage_recipient, attack):
    base_hp_damage = base_hp_damage * (1 - guard_rate)  # guard_rate TBD
# Barrier / rounding / crit / on-hit 的細排序另外裁決
```

數值例（全部 PROVISIONAL）：Boss基礎50，原尤拉承傷45；若改由克蕾雅Protect，重新計算她受30，非直接搬45；若克蕾雅自己合法Guard且正常承傷30，暫以40% Guard則為18。**但同一角色同一窗口不能同時 Protect+Guard**；兩個例子不可合成「克蕾雅Protec再Guard」。若另一角色施放 Barrier SP，是否減免HP取決於該SP目標與屏障計算層，不是基本Protect自帶效果。

### 8.2 防禦分類矩陣

| 入侵效果 | Basic Guard | Basic Protect | Specialty SP |
|---|---|---|---|
| 可守護單體HP物理攻擊 | 自己合法時減傷 | 改由守護者重算 | 逐張規定 |
| 可守護單體HP魔法攻擊 | 自己合法時減傷 | 改由守護者重算 | 逐張規定 |
| 多目標/全體HP攻擊 | 若本人有合法 Guard window 可減本人的部分，具體窗口粒度TBD | **不能攔截** | 依卡可做全隊防護 |
| 單體命中附帶詠唱干擾 | 不自動保護Casting Stability | **隨單體命中改指守護者** | 可提供 Focus Ward 等 |
| 直接綁定 Casting Instance 的干擾 | 不自動消除 | **不能攔截** | 可用針對詠唱的SP |
| 中毒/沉默/擊退等非詠唱附加 | **TBD** | **TBD**，不得假設全部轉移 | 逐卡規範 |
| 不可守護特殊攻擊 | 依Guard自身條件另定 | **不合法**且UI預先標明 | 逐卡規範 |

### 8.3 必須禁止的錯誤推論

- 「Protect消耗2RP」≠「附帶20%減傷」；羈絆可提供額外減傷只是一項未來構想。
- 「同窗口三人可反應」≠「守護者同窗口也可以同時Guard」。
- 「防禦成長讓Guard更強」≠「Guard固定減傷百分比會隨防禦成長改變」；成長首先影響常規防禦後的承傷。
- 「Protect攔單體魔法」≠「任何直接作用魔法 Casting Instance 的獨立干擾都能攔」。
- 「目標重新指派」≠「命中/閃避/暴擊判定已定案」；時序仍要單獨決策。

### 8.4 待決公式與精確規則

`hit_check_before_or_after_redirect`, `damage_rounding`, `guard_pct`, `min_chip_damage`, `barrier_layer_order`, `critical_multiplier`, `true_damage_guardable`, `poison_stun_on_hit_redirect`, `dead_target_policy`, `multi_hit_granularity`, `multiple_protectors`. 明列於14 Phase2 backlog。

## 9. Phase 2 後續核准（2026-10-14）

`P2-D08` 現已 **APPROVED**：`CritRate`、`CritDamage` 是獨立可成長屬性；暴擊率範圍 0%～100%；命中後才判暴擊，保證暴擊不保證命中；暴擊傷害依 `NormalHPDamage × (1 + CritDamageBonus)` 表達，僅套用具有暴擊資格的 HP 傷害。基礎倍率、回合各段判定、優先次序、取整仍 TBD。

`P2-D09` 現已 **APPROVED**：**敵人個別定義戰鬥元素抗性與弱點**，沒有全域固定元素相剋表；複合學科魔法可指定單一主要戰鬥元素。元素集合、倍率及元素是否額外傷 Break 皆未核准。舊 §1／§8 的 d20 或「暴擊倍率全未決」必須依此增補與 `18` 重讀；不能拿舊候選覆蓋新核准。

## 10. P2-D10～D15 設計方向已核准（細部配置仍 TBD）

採**決定性、可解釋的 HP 傷害流水線**；需要分開記錄合法指令、命中、暴擊適用、PAtk/PDef 或 MAtk/MDef 基礎傷害、元素抗性（由目標敵人逐一配置）、適用的 Guard／Protect、HP Barrier、最終 HP 及 OnHit/OnDamage、Break／Exposed 整卡事件。要遵守已核准「Guard 在正常防禦／抗性後按百分比減傷」「Break 在整張 SP 完成後才正式觸發」「命中後判暴擊」等局部先後規範；**其餘交換順序不能從示意流程偷渡成核准細節**。

**P2-D11**：建議於最終 HP 傷害階段統一取整，最低傷害規則獨立可配置；真正取整模式、最小 HP chip 值 TBD。**P2-D12**：Barrier 防 HP、Focus Ward 防 Casting Stability，疊層時序等另定。**P2-D13**：Buff/Debuff/DoT 每個狀態明定 stack、duration、tick、dispel，不能將單一固定 DoT 模型套給全部。**P2-D14**：HP0 → Incapacitated，不得正常主動行動，復活及已在詠唱中卡牌處置 TBD。**P2-D15**：該次合法行動及其應完成事件後檢查勝敗；同歸於盡及待決隊列優先順序 TBD。見19與13。

## Phase 1–2 傷害與目標補充（PRE3-R01、R03、R06～R08、R13/14；DELEGATED_DEFAULT）

合法 Protect **在命中前**改寫實際承受者；之後適用該角色的命中閃避、防禦／抗性。命中綁定狀態和擊退是否轉移，依逐效果 `follows_damage_recipient` 而非全有或全無。HP trace 方向：合法性→Protect→命中→適用暴擊→元素／攻防修正→Guard→Barrier→最後取整扣HP；Focus Ward 不吸收 HP。最後傷害採 `floor(max(0,damage))`、不強制最低1點；**這是可版本化工程預設，不是既有核准平衡參數**。DoT/HoT/Buff 各自指定 tick，依 priority/instance id 穩定處理。HP0 進 Incap，普通治療不自動復活；Exhausted 仍可被敵方攻擊／治療。核心同歸於盡事件暫測 DRAW，須再確認（詳見20）。

## USER_APPROVED: 雙方同時倒地的終局規則
在目前合法 action 與必要觸發全部結算的 outcome boundary，以 `all_enemies_defeated` 判 **VICTORY 優先**：即使我方全員在同一結算後 `HP=0 / INCAPACITATED`，仍視為劇情 RPG 通關，不顯示 `DRAW` 或 `DEFEAT`。若敵人尚有存活、我方全部失能，才判 `DEFEAT`。HP0 transition 與 `LastSpellInvalidated` 是即時事件，勝敗檢查仍於 action boundary；不允許失能角色尚未釋放的 Last Spell 之後補刀。