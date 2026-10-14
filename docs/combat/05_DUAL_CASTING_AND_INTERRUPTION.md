# 05 — 雙模式詠唱、Concentration、個體化干擾

> **2026-10-14 LIBRARY Phase 2 最新補充（現行 SoT）**：請優先閱讀 [`19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md`](19_PHASE2_APPROVED_M_D18_D31_AND_P2_D10_D16.md) 與 [`18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md`](18_MAGIC_AP_ECONOMY_APPROVED_M_D01_D17.md)。M-D18～M-D31 已核准；P2-D10～D16 的**設計方向**已整體核准，數值／部分結算邊界仍 TBD。較早段落的「P2-D08 未決」「換牌僅提案」「手牌上限 TBD」「完整詠唱較貴 MP」等屬歷史文字，與 19 衝突時以 19 為準。**僅 Library 更新，未同步 GitHub；尚無 Godot 執行／CI PASS 證據。**


## 1. 魔法世界觀

`Spell Card` 表示封裝的 術式媒介；一張魔法卡能選**破棄詠唱（Chantless）**或**完整詠唱（Full Chant）**，除非卡自定唯一施放模式；Last Spell 強制 Full。這是同一張 CardInstance 的兩種 CastingProfile，不是兩張牌。

## 2. 模式差異（APPROVED）

| | Chantless | Full Chant |
|---|---|---|
| 結算 | 合法打出後立即生效 | 跨一回合，在下一玩家階段開始預定結算 |
| 效果 | 較低威力，但部分卡可具干擾/機動性優勢 | 較強效果與隊友保護需求 |
| 扣費 | 立即扣相應AP/MP | 宣告開始時一次扣AP/MP；結算不再扣 |
| Concentration | 無 | 有；不得開始第二個Full Chant |
| 干擾 | 一般無等待窗口 | 法術有獨立 Casting Stability，可遭敵方干擾 |
| 卡牌區域 | 扣費執行後進棄牌 | 卡移入 Casting Zone，結束時移出 |

**更新：M-D21 核准同一張 SP 的 Chantless／Full Chant 預設相同 MP 成本**；舊火球例中不同 MP 的組合僅為已被新預設取代的歷史示例，不得當前期配置。AP 投入及減費另依 M-D13～M-D15、19 文件處理。

## 3. Casting Instance 結構

`casting_id, caster_id, card_instance_id, spell_id, mode, target_snapshot, planned_resolve_point, base_stability, current_stability, focus_ward, disruption_events[], concentration, can_cancel, state`。滿足最後生效條件時先檢查施法者狀態與當前目標合法性；目標死亡/消失時如何重選屬TBD。

**一名角色同時最多維持一個完整詠唱**。CONCENTRATING 不得一般普攻／戰技／魔法／道具，但可接受隊友治療/防護，僅帶 `CAST_COMPATIBLE` 的 Reaction 在合法窗口例外。完整成功結算後解除狀態，角色可正常行動。

## 4. Casting Resilience 與 Disruption Power

- Casting Resilience：該角色/Variant 的個體抗干擾能力，提高施法時起始穩定度；不是無條件中斷免疫。
- Disruption Power：強化該角色符合條件的卡牌對「目標正在施放的某一法術」造成的干擾。部分支援技能有固定干擾，明文指定不受角色倍率影響。
- Candidate `stability = floor(spell.base_stability × caster.resilience_multiplier)`；`disruption = floor(base_disruption × actor.disruption_multiplier × effect_modifier)`。**取整、倍率疊加、弱點判斷順序尚待核准**。
- 將詠唱穩定度算成每個 CastingInstance 的 `current_stability`，干擾先扣 Focus Ward，再扣 Stability；歸零一般完整詠唱遭中斷。

## 5. 獨立於本體 Break

`Casting Stability` 只存在於該次施法；歸零取消一般詠唱，或對Last Spell產生專屬失衡效果（見08）。施法結束即移除。`Break Gauge` 表示敵人本體受壓及失衡，跨多回合依規則存在，歸零帶來失衡窗口；不得混用 UI 條或程式欄位。

## 6. 保護與中斷返還

Barrier 吸收HP傷害；Focus Ward 保護詠唱，不代表吸收HP。特殊複合卡要明示雙效果。**現行已核准 M-D22～M-D24**：Full Chant 因 Casting Interrupt 中斷時，在中斷成立後立即返還**部分 MP**（比例及取整未定，50% 僅測試候選）；**AP 不退、Overload 債務不取消**。主動取消、目標失效、已完成後遭 Spell Counter 反制的退款仍待另外定義。必須明確決定：玩家可否手動取消、角色死亡/暈眩/沉默時是否取消、返還何時執行與卡牌最後去哪個區。

## 7. Boss 互動與時序

Boss蓄力時，玩家在其施法窗口用多張牌累積干擾；敵方實際施放前可能再進Reaction窗口。Boss可用自身攻擊／召喚物／被動效果干擾玩家。**禁止在沒有明示額外行動的情況下讓Boss同回合同時蓄力又普通攻擊。** 已公開的意圖不能偷換，例外條件要明示。

## 8. 確定性 UI 預覽

顯示：卡牌基礎干擾、角色倍率、法術弱點/抗性、Focus Ward吸收後的`Stability before→after`、是否會打斷；不引入非可預測的隱性骰值。必須顯示 Full 將在何時完成、被中斷的後果。若效果有亂數則顯示範圍與機率（待傷害系統決策）。


---

## 9. Phase 1 防護／干擾的目標語義（P1-D14 APPROVED）

將攻擊事件與直接作用於 Casting Instance 的干擾事件**分開建模**。單體攻擊可包含 `HP_DAMAGE` 與 `ON_HIT_CASTING_DISRUPTION` 兩個耦合效果；當合法 Protect 攔截該次攻擊時，兩者的實際承受目標轉移為守護者。**被保護的施法者不應再因同次攻擊的命中附帶干擾失去 Casting Stability**。守護者若沒有符合條件的施法實例，該附帶干擾不應神奇地回頭打原施法者；其處置須遵循效果的「受影響對象」契約。

另一方面 `CASTING_INSTANCE_DIRECT_DISRUPTION` 明確指向 `casting_id` / `casting instance id`，它**不是**命中目標的單體攻擊附屬項，不受 Guard 或基本 Protect 攔截；必須靠 Focus Ward / 專用反制或其他明確許可的特殊SP應對。若同一 Boss招式先發射攻擊又另帶獨立 Casting Lock，必須拆開敘述與事件，UI須顯示哪些可守護、哪些無法守護，避免「保護成功但看似失敗」的體驗。

> 示例（傷害30、干擾15、Stability20皆 PROVISIONAL）：Boss對正在 Full Chant 的尤拉發射可守護的魔法箭；克蕾雅 Protect 成功攔截，傷害以克蕾雅魔防重算。該箭命中附帶的15點干擾**不影響尤拉**。但同時若另有敵方持續魔法`Casting Lock(casting_id=yura_spell)`，該直指干擾仍繼續，除非獨立反制。

**與舊文的取整及護盾規則相互獨立**：`FocusWardAbsorb` 不應被當成HP Barrier；`Casting Stability`不能被Guard「40%減傷」自動削減，因40%本身也只是假設數值。對於兼有傷害與干擾但沒有命中觸發標記的舊技能資料，升級時必須手動分類，不能默默全轉向。

### 9.1 驗收場景

- 單體攻擊帶 `on_hit_cast_disruption`、Protect轉向合法且命中：原施法者 Stability 不減；守護者承受按其防禦重算的HP傷害。
- 直接`target_casting_id`干擾即使同時存在守護者：仍以原 Casting Instance 做穩定度計算。
- 未被命中的攻擊是否觸發附帶干擾遵循該效果的命中前提（命中演算法 TBD），不得只憑存在一條攻擊事件就無條件減穩定。
- 特殊 Focus Ward SP 可作用於合法 Casting Instance，但非該類卡的基本 Guard 不能取代其工作。

## 9. Full Chant 的 MP/AP 風險結算（M-D21～M-D24）

雙模式 SP 預設**相同 MP 成本**，提交時即扣 AP/MP、Full Chant 成立 CastingInstance 後延遲效果；成功完成不退款。若詠唱中 Casting Stability 被合法干擾至 Interrupt 門檻，確定 `CastingInterrupted` → 取消原定尚未產生的魔法效果 → **立即部分退 MP 且不得超過當前 MaxMP** → 結束施法實例／按合法區域規則移卡；**不退 AP、不清償或取消 Overload 債務**。中斷比率、取整、主動取消／目標死亡／Spell Counter 另列 TBD，勿套用「一律50%」。

## Phase 1–2 Full Chant 移區與 HP0 邊界（PRE3-R12/13/15；DELEGATED_DEFAULT）

通常 Full Chant 提交時已支付 AP/MP，卡實例進 Casting Zone；正常施放完成或合法中斷後進 discard（卡明文 exile/return_to_hand 例外）。一般 Full Chant 不提供免費通用 Cancel 指令。因 HP0 失能而取消尚未釋放的普通詠唱，並非 M-D22 定義的 `CastingInterrupted`，不得觸發部分 MP 返還；若確定是施法干擾打斷才執行立即部分 MP 退款（比例仍待配置）。已提交 **Last Spell 不可取消**，其施法者HP0的特殊處理依20的 PRE3-R15，正式可玩版須 CORE_CONFIRM。

## USER_APPROVED Last Spell forced invalidation（與一般 Casting Interrupt 分離）
- **一般 Full Chant**：達到合法干擾門檻的 `CastingInterrupted` 立即返還部分 MP（比例 provisional），AP 與 Overload 不退；若 caster 因 HP0 失能致無法施法，按失效處理且**不得錯套 CastingInterrupted 的 MP 退款**。
- **Last Spell**：一般敵方干擾依 Last Spell 原有延遲／削弱特例，並非一打斷就消失；但**詠唱者在生效前 HP0 時必定即時 invalidated**、取消已排程的效果，不返任何資源、不恢復每戰一次使用權。這是高優先級 `CASTER_INCAPACITATED` 失效，而非玩家取消、Spell Counter 或普通 Casting Disruption。
- 成功釋放的法術不得被**後來的 HP0 事件追溯撤銷**。