# 26 — Universal Basic Magic & Starter Deck v0.3

> 日期：2026-10-15  
> 決策狀態：**USER_APPROVED_DIRECTION（所有角色具備基礎攻擊／治療／防護魔法的配牌資格）**；卡名、MP/AP、係數、卡片配置與平衡目標均 **CONTENT_PROVISIONAL／NOT TESTED**。  
> 適用範圍：Godot 4.x Astraea 三人 JRPG + 每角色獨立牌組。唯一系統權威是 `docs/combat/00`–`25` 的最新有效 Combat Rules 及後續明示核准事項。**不引用**舊 `Life_RPG_Astraea_GDD_v1.1.md`、舊 `COMBAT_SYSTEM.md`，**不重引 Counter-Function**。  
> 版本優先順序：本次 USER_APPROVED 方向 > 先前 USER_APPROVED/P1/P2/M > `20` DELEGATED_DEFAULT > 此處 BALANCE_PROVISIONAL。此檔為 25 的增量；除列明之「通用卡池／起始牌組」外，25 的候選角色與 CardDefinition 持續有效。

## 1. 本次正式確認的重大內容方向（ADR-CONTENT-001）

- **角色職能是專精，不是能力排他。** 初期劍士 `ren_swordsman_v1`、爆發法師 `akane_burst_mage_v1`、治療輔助 `tsumugi_healer_v1` 都有資格裝備並使用通用基礎**魔法攻擊、HP 治療、HP 防護**卡牌。角色後續仍可學習其他合法 UNIVERSAL 卡。
- **基本魔法仍是需要抽取的 SP。** `UNIVERSAL` 指配置資格，不代表戰鬥中無條件持卡。三人各自 12 張 SP 實例、開局手牌4、每個 Player Phase 不足4才補足、手牌上限8、每人每階段可免費棄1抽1一次（遵守抽／棄牌事件）。
- 不改動獨立的非牌卡指令：`Basic Attack`、基本 `Guard`、基本 `Protect`、`Analyze`、`Item` 等照最新版規格執行；`Last Spell` 獨立槽，不佔12 SP。
- **角色專精由進階 SP、效率、效果與被動形成。** 紬可使用相同 U05，另外有更有效的單體／群體治療與防護、支援被動；蓮／朱音使用 U05 亦可治療隊友，代價是自己的 AP、MP 和該次抽到／配置卡片的機會成本。
- 主角職能決策維持：蓮初期固定劍士，後期以解鎖的 `Character Variant` 才可換其他職能，換形態需重新 `ValidateLoadout`；不因此禁止他初期配置 UNIVERSAL 魔法。
- 無既有明文 `Revive` 的普通治療不可復活 `INCAPACITATED`；治療 `EXHAUSTED` 可恢復 HP 但不可恢復行動能力。HP/MP 仍按既有各自上限截斷。

## 2. 外部設計參考（只借鏡，不移植機制）

1. Guild Wars 2（官方職業說明 https://www.guildwars2.com/en-gb/the-game/professions/；治療技能參考 https://wiki.guildwars2.com/wiki/Healing）：不同職業可同時貢獻輸出、防護、支援；專業治療者再透過職業特色／Healing Power 產生差異。**Astraea 借鏡：基礎跨職能可用、專精決定效率。** 不引入 GW2 自補欄位、動作技能欄或其公式。
2. Bravely Default II（Square Enix 官方 https://www.jp.square-enix.com/bd2/battle/；https://eu.store.square-enix-games.com/bravely-default-ii---digital）：主／副職業與技能搭配提升自由度，但職業各自擅長不同效果。**Astraea 借鏡：配牌自由與職能辨識能共存。** 不移植其職業切換或 Brave/Default 行動經濟。
3. Gordian Quest（官方 https://gordianquest.com/）：三位英雄的不同職能、牌組與隊伍協同。**Astraea 借鏡：獨立牌組仍保留可辨識的專長和聯動。**

## 3. Universal Basic Magic: v0.3 初始共用卡池

以下數值皆為候選，且不賦予所有角色無需成本的魔法。相同 `CardDefinitionID` 可分別配置於多名角色；每張實例仍有自己的 `CardInstanceID`。

| ID | zh-TW 名稱 | eligibility | 候選成本 | 候選效果 | 模式／合法性 |
|---|---|---|---|---|---|
| `U01` | 奧術彈 | `UNIVERSAL` | 1 AP + 2 MP | 敵單：Chantless `MAtk×0.85`、Full `MAtk×1.45`，以既有傷害流水線計算 | DUAL；兩模式相同 MP；Full 延時、可受 Casting Disruption |
| `U02` | 魔力屏障 | `UNIVERSAL` | 1 AP + 2 MP | 指定有效友軍 +140 HP Barrier（本候選內容版本、逐卡有效期） | INSTANT；只處理 HP Damage，不保護 Casting Stability |
| `U03` | 專注護符 | `UNIVERSAL` | 1 AP + 1 MP | 我方合法施法實例 +8 Focus Ward | INSTANT；只保護該次 Casting Stability；無施法實例時不可用 |
| `U04` | 魔力調律 | `UNIVERSAL` | 1 AP + 0 MP | 友軍／自身恢復3 MP | INSTANT；受目標當前 MaxMP 截斷；若沒有可恢復 MP 的合法目標不能使用 |
| **`U05`** | **初階治癒術** | **`UNIVERSAL`** | **1 AP + 2 MP** | **指定有效友軍恢復150 HP** | **INSTANT；僅能指定 HP>0 且 HP 未滿的合格角色；不含 Revive／Dispel／Barrier** |

- U05 與 U01/U02 在**資格**上相同，不額外設 `HEALER` 限定，也**不**保證其傷害／治療／護盾結果相等。
- U05 目前採固定回復量作首版測試，不直接依 `MAtk` 提高治療：否則全隊最高魔攻者可能不合理地成為最強的通用治療者。若後續新增 HealingPower/HealMultiplier，需清楚定義屬性來源及 `Character/Variant`、Buff 的可疊加範圍，並另作平衡審核，不作為本次既定全域規則。
- 治療只回復 `actual_heal=min(target.max_hp-target.hp,150 + explicit_valid_modifiers)`，不因 HP 滿溢變 Barrier、MP、AP；本例 `target.hp>0` 規則也適用於所有沒有 `revive` 標籤的一般治療。
- 紬 v0.2 的被動 `TSUMUGI_P01`「每 Player Phase 首個合格 HEAL SP +60」維持 CONTENT_PROVISIONAL，可套至紬自己合法使用的 U05 或 T 系治療；不是限定只對她的專屬卡觸發。
- **須補充各卡 i18n**：例如 `card.u05.name`, `card.u05.description`，與 `en` 對應本地化。展示名稱不用於戰鬥決策。

## 4. 角色職能特徵不變，但不是行動禁止表

| 角色 | 保留之主專長 | 也能做的基礎行動 | 專精差異（候選） |
|---|---|---|---|
| 朝霧蓮 `ren_swordsman_v1` | 物理攻擊、Break、雙人 Combo、援護 | U01 攻擊魔法、U02 護盾、U05 治療 | 近戰傷害／Break SP、雙人 setup、專屬 Last Spell |
| 九條朱音 `akane_burst_mage_v1` | 高 MP 成本爆發、雙模式詠唱 | U02 護盾、U05 治療 | 特化魔法傷害及 Full Chant、魔法壓力與高輸出；治療消耗原本可打出爆發的資源 |
| 白石紬 `tsumugi_healer_v1` | 高效治療、群補、防護、支援 | U01 攻擊魔法及 T09/T10 進攻技能 | 同 AP/MP 下更高的回復、額外 Barrier、全隊支援與進攻附帶治療，**並不壟斷治療卡資格** |

特別注意：`T01`（200HP，1AP+2MP）與 `U05`（150HP，1AP+2MP）有數值差距；紬的候選被動可於首次合格施法增加 +60 HP，使其形成專精，而不修改 U05 通用資格。兩者皆不得復活 HP0 角色；T09/T10 是候選攻擊型角色卡，不在本次新增新的元素全域列表。

## 5. 三副 Starter Deck v0.3：每人 12 張，確切 CardDefinition 清單

`25` 內既有 U01–U04 + 各8張角色卡的方案保留為 v0.2 歷史示例。本 v0.3 **取代 v0.2 的 §9 Starter Deck 配置**，以 U05 新增通用治療功能。起始牌組各卡都先採每種定義1張，以免提前凍結全遊戲同名卡限制。未配置者仍保留在可取得／換裝的候選卡池中。

```text
REN_STARTER_V0_3 = [U01,U02,U03,U04,U05,R01,R02,R03,R05,R06,R07,R08]
AKANE_STARTER_V0_3 = [U01,U02,U03,U04,U05,A01,A02,A03,A04,A05,A06,A07]
TSUMUGI_STARTER_V0_3 = [U01,U02,U03,U04,U05,T01,T03,T04,T05,T06,T09,T10]
```

| 人物 | UNIVERSAL | ROLE/CHARACTER | 共計 | v0.2 → v0.3 替換理由 |
|---|---:|---:|---:|---|
| 蓮 | 5 | 7 | 12 | `+U05 -R04`：R04 自我 Barrier 與 U02／R08 重疊，改為新手基礎治療教學 |
| 朱音 | 5 | 7 | 12 | `+U05 -A08`：A08 高階專屬爆發仍可日後取得，初期不把全部 AP 集中在輸出 Buff |
| 紬 | 5 | 7 | 12 | `+U05`，保留 T09 光羽彈、T10 祈光脈衝等專精攻擊；減少全治療卡造成的卡手，T02/T07/T08 後續仍可配牌 |

**注意：** `T09`/`T10` 是前輪討論已提出的候選新卡，但並未納入 25 的正式卡目錄。為避免 ID 幽靈，本文件將其候選定義補齊：

| ID | 名稱／資格 | 候選成本 | 候選效果與界線 |
|---|---|---|---|
| `T09` | 光羽彈／`CHARACTER:tsumugi` | 1 AP + 2 MP | DUAL 敵單魔法，Chantless `m_atk×0.90`、Full `m_atk×1.40`；同 MP，不額外賦予新元素弱點分類 |
| `T10` | 祈光脈衝／`CHARACTER:tsumugi` | 1 AP + 3 MP | INSTANT 敵單魔法 `m_atk×0.80`，**成功造成 HP 傷害且效果合法完成後**，一次恢復目前 HP 比例最低的有效非倒地隊友 `80 HP`。滿血時攻擊仍合法，治療為0；Miss／只打在 Barrier 未減 HP → 不觸發治療。不得每 hit 重複觸發，也不得產生 Revive |

`T10` 的同 HP 比例排序以穩定 `party_order` 再 `actor_id` tie-break，確保 Replay deterministic。

## 6. Godot 內容驗證與資料結構

```json
{
  "content_version": "starter-party-v0.3-provisional",
  "card_id": "U05",
  "name_key": "card.u05.name",
  "eligibility": {"kind":"UNIVERSAL"},
  "type": "HEAL",
  "casting_mode": "INSTANT",
  "cost": {"ap":1,"mp":2},
  "targeting": {"team":"ALLY","scope":"SINGLE","hp_above_zero":true,"missing_hp_required":true},
  "effects": [{"kind":"HEAL_HP","base_amount":150,"can_revive":false}]
}
```

此為**內容 schema 示意**，不能跳過現有 Domain schema 驗證直接存入場景。 `CardDefinition` 與 `CardInstanceID` 分離；12 張每人的唯一實例不可跨 draw/hand/discard/casting 複製；`ValidateLoadout` 應校驗每名角色配置恰好12、eligibility 合法、相應 `Variant` 有效。雙詠唱 AP/MP、MP 持續、不存在自然回魔、Reactions 先 queue 後 commit、Exposed/Break 以及 Last Spell 皆維持原 Combat Rules。

## 7. 平衡測試與防止專精消失的 Gate

1. **通用治療資格**：蓮、朱音、紬合法持 U05；在 HP 合法缺損且有 AP/MP 時皆能施放；錯誤地設定 `HEALER` tag 導致其他角色禁止出牌必須 FAIL。
2. **治療實際值**：使用者攻魔較高不應無依據令 U05 回更多；紬的明文治療被動符合觸發次數才加成；溢補截斷，普通治療不得解除 Incapacitated/Exhausted。
3. **資源選擇**：蓮／朱音出 U05 是真實 AP/MP/手牌成本，不能同時算一次免費輸出。MP 歸零、AP 不足、Concentrating、Exhausted 的非法情形不得扣資源。
4. **被動補師價值**：在多種 Boss 傷害輪廓下比較「紬治療與 U05 治療」有效回復／AP、有效回復／MP、過量治療比例；若朱音高魔攻同時補得更有效，視為 Content Balance FAIL。
5. **卡手**：對3套36實例，開局起始4張的 deterministic seeds 測試空轉率；標示某階段特殊卡未有合法目標造成的頻率，避免僅增加通用治療卻反使無傷期更常卡手。
6. **角色協同**：至少100固定 seed × 不同策略（爆發、保守、詠唱保護、通用緊急救援），檢查勝率、輸出、保護、治療有效率、Combo、AP占比。對照具有 U05 與沒有 U05 的兩組實驗。
7. **系統規則回歸**：基本 Guard/Protect 不需抽卡；U02 Barrier 防HP、U03 Focus Ward 防Stability；Last Spell 不在12卡、不改 Exhausted／HP0 forced invalidation；同一輸入同seed同內容版應有相同 event trace/hash。

`SPECIFICATION: DESIGNED`; `GODOT/CI/PLAYTEST: NOT EXECUTED`; `BALANCE: PROVISIONAL`。不得對外宣稱已平衡或已發布至 GitHub。

## 8. 本次不擴充的未決範圍

- 不將 U05 變成無需手牌的基本指令；若未來希望所有角色不用抽卡就能施治癒術，屬不同玩法，需新的明確重大決策。
- 不要求全隊每人**必帶** U05：UNIVERSAL 是「可配置權」，不是「固定欄位」；Starter 皆先帶1張是教學與平衡候選。
- 不在本次新增一種全域 HealPower 能力值、Revive、自然每回合回 MP，或完整詠唱治療的通則。
- 不變更每位角色恰12卡、全隊共享 BaseAP6、補至手4上限8、免費換1／階段、RP／Reaction、雙詠唱同MP、Exposed/Break/Combo 的正式契約。