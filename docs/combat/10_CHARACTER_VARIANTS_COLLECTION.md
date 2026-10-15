# 10 — 角色、Variant、Skin、卡池及配置資格

> **Documentation status · 2026-10-15 — APPROVED_DETAIL + LATER_CONTENT_DIRECTION**：Character／Variant／Skin 與配牌資格參見 25 主角初始劍士、後期 Variant 解鎖；26 確認通用基本攻擊／治療／防護魔法對所有符合資格角色開放。 現行導航：[Combat Spec Index](COMBAT_SPEC_INDEX.md)；缺口：[Open Issues](COMBAT_OPEN_ISSUES.md)。**Godot Domain M1～M5.5：1,238/1,238 通過；100 場固定 Seed 的完整戰鬥與 Replay 已驗證（[Master CI #38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741)）。Scene／真人可玩／正式平衡仍未驗證。** 以下舊段落保留歷史脈絡，不是新測試或新核准。


## 1. 定義（APPROVED）

`Character`: 故事中的人（故事身份）。`Variant`: 其可玩戰鬥形態，改變基礎HP、閃避、詠唱韌性、干擾能力、被動、專屬卡使用權和Last Spell。`Skin`: 只變視覺，不改技能與戰鬥數值。兩者不得混淆，避免純造型改變配牌合法性。

## 2. 卡牌種類

| eligibility | 原則 |
|---|---|
| UNIVERSAL | 所有符合基本需求的角色 |
| ROLE_TAG | 特定職能/武器/魔法類別標籤 |
| CHARACTER | 指定故事角色（可供其符合條件的Variants） |
| VARIANT | 特定戰鬥Variant專用 |

卡有稀有度 R/SR/SSR/UR，但高稀有度不應只靠巨大數值碾壓；宜用戰術機制、建立牌組的選擇增加差異。沒有已批准的「高稀有度限制攜帶張數」。

## 3. 雙卡池

使用者規劃角色池與卡牌池；收藏/抽取系統不應埋在戰鬥核心。核心接收「已驗證的角色Variant+牌組」快照，並根據確定性規則演算；抽取概率、保底/重複角色處置/付費設計屬獨立商業規格，尚未定義。抽到卡不代表當場戰鬥能直接用，需裝備在符合資格的12張牌組中。

## 4. 裝備與安全規則

開戰前做 `ValidateLoadout`：角色Variant有效、卡牌ID存在、資格合法、12張、收藏實例/數量合法；同名卡張數與罕見卡上限TBD。裝備切換Variant時重新驗證整副牌、Last Spell、能力值。`Skin`切換不應讓戰鬥state hash變化（除非hash含 cosmetic metadata，建議不要）。

## 5. 角色差異與平衡

Casting Resilience 和 Disruption Power 個體化，避免所有角色只是不同圖像的相同卡片輸出；Support可用固定削減或FocusWard，即使非干擾專精也有意義。追蹤每個職能參與AP比、施法完成率、死亡率、Boss中斷率與UR對戰術多樣性之影響。

## 6. 資料例（僅示意）

```json
{"character_id":"kurea","variant_id":"academy","skin_id":"default","stats":{"max_hp":100,"evasion":0.05,"casting_resilience":1.0,"disruption_power":1.3},"role_tags":["swordsman"],"last_spell_id":"kurea_final","deck_card_instance_ids":["..."]}
```

所有示意數字均非核准平衡值。


---

## 7. Phase 1 防禦成長與未來羈絆掛鉤（P1-D08）

本次核准的是**基本守護/防禦的行為類別**，不是固定每角色的減傷值：Guard先按該角色防禦與抗性算一般承傷，然後乘固定Guard減傷比例；Protect更換實際承傷者，使用守護者的防禦/抗性重算。於是更高防禦、抗性、裝備或Variant數值本來就可能降低最終損傷，但**不因此免費附加反擊、全隊護盾或 詠唱 干擾免疫**。

使用者提出未來可設 `Bond`（羈絆）使特定組合的Protect承傷更少。**狀態：FUTURE CANDIDATE / NOT MVP**。何時解鎖、誰與誰、百分比、疊加/加算/乘算、效果上限、是否與SP互斥、UI提示皆未核准。可以在工程架構預留可選modifier hook，但預設不能啟用羈絆減傷，也不能在戰鬥內憑關係值隱性減傷。

角色定位仍應靠可持卡資格、技能差異、一般屬性及Casting Resilience/Disruption Power形成多維表現，不應只以「坦克Guard幾乎無敵」代替特殊SP的玩法。未來若有通用 Evade 仍需新ADR，現時**沒有所有人可用的基本 Evade Reaction**。