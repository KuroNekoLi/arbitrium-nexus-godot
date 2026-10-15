# 19 — Phase 2 後續核准決策與設計收斂（M-D18～M-D31；P2-D10～D16）

> **Documentation status · 2026-10-15 — APPROVED_M_D18_D31_AND_P2_D10_D16_DIRECTION**：這是生效的唯一 19：M-D18～31 已核准，P2-D10～16 核准的是**方向**而非固定數值；上游舊檔名已歸檔，不是另一套 Canon。文內原 `LIBRARY ONLY` 為來源當時狀態。 先讀 [Combat Spec Index](COMBAT_SPEC_INDEX.md)；目前未驗證項目見 [Open Issues](COMBAT_OPEN_ISSUES.md)。**M1～M5.4 1,081 項 Domain CI 有證據，M5.5 仍未驗證。** 舊正文的「當時狀態」僅供歷史追溯，不得升格為新核准或新 CI。


> **2026-10-14／LIBRARY ONLY CHECKPOINT**。本文件是既有 `16`、`18` 決策快照的後續增量，搭配 `00`／`01`／`02`～`05`／`11`／`13`／`17` 使用；保留既有 P1／P2／M-D01～M-D17 已核准契約。2026-10-14 使用者明確逐項確認 M-D18～M-D31，並**整體同意** P2-D10～D16 的建議設計方向。這是**設計規格已收斂**，**不是 Godot 已實作、CI 或平衡驗證 PASS**。具體未選定參數維持 CONFIGURABLE/TBD；M-D04 的跨多輪 Overload 債務仍為 PROVISIONAL 試行。

## 1. 魔法 AP 系統續決策（M-D18）

| ID | 狀態 | 契約 |
|---|---|---|
| **M-D18** | APPROVED A | **當回合共享 `CurrentAP` 沒有額外硬上限**；合法 SP 的當回合 AP 增加、返還可以超過每個 Player Phase 的 `BaseAP=6`。回合末未使用 AP 依 M-D07 1:1 嘗試轉 RP，仍受 **RP 預設上限 6**（M-D08；特定 SP 可增 cap）限制；額外 AP **不會**跨 Player Phase 保存，RP 在緊接 Enemy Phase 結束無條件歸零（M-D09）。防無成本無限循環（M-D12）。 |

**例**：6 AP → 使用成本 2 AP、獲得 8 AP 的 SP → `CurrentAP=12`；若階段末仍有 9 AP，沒有提升 RP cap 時只能取得 6 RP，超額 3 AP 消失。這是資源規則示例，不表示已核准該具體 SP。

## 2. 個人 MP、雙詠唱成本與中斷退款（M-D19～M-D24、M-D31）

| ID | 狀態 | 契約 |
|---|---|---|
| **M-D19** | APPROVED C | 個人 MP 跨回合保留；**預設沒有無條件的每回合自然回 MP**。仍維持每角色每 Player Phase 第一次普通攻擊可恢復 MP（恢復量 TBD）。明文角色特性、SP、道具、Buff／持續效果可在符合各自時機／條件時恢復 MP；不可憑空給所有角色固定自然回魔。 |
| **M-D20** | APPROVED A | 恢復 MP 不得超過**當下生效的 `MaxMP`**；`newMP = min(MaxMP, CurrentMP + positiveMPRecovery)`，超額恢復直接浪費，不暫存或轉其他資源。特性、裝備、Buff 可改變 MaxMP（見 M-D31）。 |
| **M-D21** | APPROVED A | 同一雙模式 SP 的 **Chantless 與 Full Chant 預設消耗相同 MP**；兩者主要在立即／延遲、詠唱干擾風險及技能效果上有差異。不可將舊版示例的 Full Chant 一律較高 MP 當成現行預設；特殊 SP 例外要另行明文。 |
| **M-D22** | APPROVED B | **Full Chant 因詠唱干擾而被成功打斷時返還部分已支付 MP**。返還比例／取整仍 CONFIGURABLE/TBD；50% 只是未核准測試候選。此決議不自動涵蓋主動取消、目標失效、成功施法後遭 Spell Counter 等不同失敗原因。 |
| **M-D23** | APPROVED A | Full Chant 中斷 **不返還 AP，也不取消該 SP 產生的 Overload 債務**。在下一個 Player Phase 仍依 M-D06 從 `BaseAP + APBonus` 扣除舊債；不等於「詠唱打斷只能發生在 Enemy Phase」，合法特殊反擊／環境事件仍可能改變發生階段。 |
| **M-D24** | APPROVED A | M-D22 的部分 MP 返還在**中斷正式成立時立即結算**，再以 M-D20 上限截斷；不等待下次 Player Phase，也不能在一個效果結算中任意插入非法行動。 |
| **M-D31** | APPROVED B | **角色各自可擁有不同的基礎 `MaxMP`**，並可透過角色養成、裝備、特性、Buff 提高；確切基礎值及成長曲線 CONFIGURABLE/TBD。高 MaxMP 不直接代表更高魔法傷害。 |

**已核准的不變條件**：MP 按角色獨立；AP 按隊伍共享；施法提交時先支付該 SP 的 AP／MP（Full Chant 延遲效果不是延遲付費）；只有符合 M-D22 的 Casting Interrupt 中斷退款例外，退款後不得超過 MaxMP。`Casting Stability` 屬 CastingInstance、不同於敵人 `Break Gauge`。在玩家階段 Full Chant 提交時進 Concentration；合法中斷後解除該施法實例；具體卡牌移區、同時觸發事件優先級仍需實作細規或標 TBD。

## 3. 手牌與免費換牌（M-D25～M-D30）

| ID | 狀態 | 契約 |
|---|---|---|
| **M-D25** | APPROVED B | 每位角色的**手牌上限 8 張**，但**每個 Player Phase 開始僅補至 4 張**，不是固定抽 4 張；保留未用手牌。若已持有 4～8 張則基本補牌抽 0 張；額外抽牌 SP 可增加至 8 張。容量不足時只抽入可容納張數，超額抽牌不執行，也不憑空棄掉抽牌堆卡牌。 |
| **M-D26** | APPROVED B | 每名角色每個 **Player Phase 有一次免費「棄 1 張、抽 1 張」換牌**的獨立基本指令，不需要抽到換牌 SP，消耗 0 AP／0 MP，未用次數不累計；執行後玩家可自由繼續操作同一或其他角色。 |
| **M-D27** | APPROVED B | 本次免費換牌**不能立即抽回被選擇棄掉的同一張 `CardInstance`**；可抽到牌組中不同實例的同名 SP。實作可暫時隔離選定實例，結束換牌後才放回通常棄牌堆。 |
| **M-D28** | APPROVED B | 免費換牌的**棄牌與成功抽牌均屬正式遊戲事件**，合法卡牌、角色特性、裝備、Buff 能依明文觸發；必須符合事件條件、使用次數與 M-D12 的防無限循環限制。抽牌失敗不可偽造 `CardDrawn`。 |
| **M-D29** | APPROVED A | 執行免費換牌前需**存在合法替代卡牌**（排除本次棄置的原實例）。若不存在，操作拒絕，**不棄牌、不抽牌、不耗換牌次數、不觸發任何棄／抽牌事件**，AP/MP 仍為 0；之後若出現替代卡，可在同 Player Phase 重試。 |
| **M-D30** | APPROVED A | 免費換牌採**明確事件時序**：先通過替代卡檢查 → 原卡離開手牌但暫時隔離、防立即抽回 → 產生正式棄牌事件 → **先結算棄牌觸發效果** → 再按合法牌庫／洗牌規則抽替代卡 → 若成功，產生並結算抽牌觸發效果 → 換牌結束原卡進棄牌區。 |

**抽牌守恆**：每角 12 卡在 hand / draw / discard / Casting Zone / 其他合法獨立區域中保有唯一 `CardInstanceID`。洗牌採 seeded PRNG；手牌 8 張是上限，不是每輪補至 8 張；Analyze 是獨立情報指令（0 AP／MP／RP、每場全隊 2 次），**不是 SP，也不算抽牌／免費換牌**。

**未固定的操作邊界**：如果 M-D30 棄牌觸發效果改變了其他卡牌的位置，導致原本合法的替代卡不再存在，須讓引擎記錄可預期的合法結果且不重複造牌；具體 fail/rollback 政策另以工程測試確定，**不因此推定可抽回原實例**。Concentrating、Exhausted、Incapacitated 的免費換牌可用性仍依角色合法行動規則決定，不擅自新增例外。

## 4. Phase 2 剩餘設計方向（P2-D10～D16）— 使用者整體同意

> **授權範圍**：使用者表示「我全部同意了」來接受助理上一輪表列的 Phase 2 建議方向。以下標為 **APPROVED DIRECTION**，不表示使用者逐項確認了尚未呈現的精確倍率、演算法、時限或特殊邊界。未定數值及算術先後的具體細節仍標 `CONFIGURABLE/TBD`，可做工程方案但不能偷換成最終平衡定值。

| ID | 狀態 | 已同意的方向 | 尚待配置／驗證 |
|---|---|---|---|
| **P2-D10** | APPROVED DIRECTION | **固定、決定性、可追蹤的傷害計算流水線**：動作合法性／資源扣除、命中與暴擊適用性、HP 傷害及目標防禦／元素修正、適用 Guard／Protect、HP Barrier、HP／狀態效果、整張 SP 後 Break／Exposed 等事件，遵守既有更精確的 P1/P2 決議；同輸入和同 RNG seed 結果一致。 | 元素／暴擊／浮動／盾層／最低傷等非已核准修正間的**完整交換順序**待數據、測試與明確規範；不得由概要序列誤認為已核定所有細節。 |
| **P2-D11** | APPROVED DIRECTION | **HP 傷害採最後階段統一取整的設計方向**，避免中途多次捨入；**最低傷害規則獨立配置**，不可偷偷設固定保底 1 點。 | 四捨五入／向下取整等實際模式、最小傷害值與例外為 CONFIGURABLE/TBD。 |
| **P2-D12** | APPROVED DIRECTION | **Barrier 專門處理 HP 傷害、Focus Ward 專門保護 Casting Stability**，保持互不混用的防護資源。 | 疊層、穿透、先後、生效期限、消散與可同時存在等精細條款待逐卡配置／測試。 |
| **P2-D13** | APPROVED DIRECTION | Buff、Debuff、DoT 的**持續時機／層數／可否疊加／驅散標籤**由各狀態明文定義；可用標準化狀態欄位與固定 tick 事件實作，不暗設所有狀態同一持續時間。 | 具體狀態列表、上限、tick 時序、重複效果組合、DoT 致死時序待規格實作或測試。 |
| **P2-D14** | APPROVED DIRECTION | 角色 HP 歸零進入 **Incapacitated**，不得繼續執行一般主動行動；不採無根據的永久角色死亡處理。 | 復活、當下手牌／CastingInstance 清理、被動狀態、AoE 選取及 Exhausted 的互動細則 TBD。 |
| **P2-D15** | APPROVED DIRECTION | **當次合法行動及應隨其結算的效果完成後，進行勝敗檢查**，不在未完成合法整卡多段效果中任意截斷；與已核准 Break 的整卡結算邊界相容。 | 雙方同時 HP0、Last Spell、召喚物、延遲死亡與尚在事件佇列的優先級仍 TBD。 |
| **P2-D16** | APPROVED DIRECTION | Godot Domain Engine 採 **seeded RNG、事件記錄、重播與邊界驗收**；同 seed + 同 command tape + 同規格版本產出同結果，任何 UI 動畫不得改變資源或結果。 | 尚未執行程式測試；測試案例是規格與期望，不可宣稱 PASS。 |

## 5. Phase 2 關閉條件與跨文件優先級

- **Phase 2 設計方向：全部已批准並收斂**。仍存在「具體數值／部分邊界細則待正式設定」，這些可由後續平衡與工程驗收補齊，而不反覆詢問一般 A/B/C。
- 已核准 P1/P2/M 系列高階玩法契約優先；本檔補充 M-D18～M-D31 與 P2-D10～D16，不抹除 `16`／`18` 早期歷史決策。**M-D04 跨輪債務仍 PROVISIONAL，不是 APPROVED 最終值**。
- **工程完成不等於設計核准**：目前僅完成文件核准與規格描述，尚無 Godot 真正執行 log、CI PASS 或平衡數據。
- 此次作業**只同步 ChatGPT Library**；沒有要求或確認 GitHub master 發布相同最新版本。日後如需 GitHub 同步應另行驗證內容哈希與 commit。


## 6. 2026-10-15 A 方案：異名來源 19 快照對照（非新規則）

來源 `astraea-combat-rules@cac49361` 使用 `19_PHASE2_FINAL_APPROVED_M_D18_D31_P2_D10_D16.md`；目標本文件為**唯一現行第19號權威檔名**。兩份檔案對 **M-D18～31** 的 AP／MP、手牌、換牌、退款及 **P2-D10～16** 的傷害／狀態／重播**沒有發現互相否定的核准方向**；來源有更長的逐題追溯和解釋，已在 `UPSTREAM_RECONCILIATION_A_2026-10-15.md` 留下對照，完整歷史原文歸檔於 `archive/upstream_19_phase2_final_2026-10-14.md`（非現行 Canon）。

**跨期最終裁決**：本表中 P2-D15 同時倒地 `TBD` 及 Last Spell 施術者 HP0 的舊描述已被較新的 20/21 USER_APPROVED CORE-01/02 取代：同一合法結算內雙方最後單位都 HP0 時玩家 `VICTORY`；Last Spell 發動前施術者 HP0 則立即強制失效，不會死後續放；Reaction 不因真實時間自動 Pass、2.5D 不帶來自由走位。這是已核准規則的**優先級標註**，不修改設計內容。Python balance HP2700、攻擊×1.7、Break22 均只是 `BALANCE_PROVISIONAL`，並非此決策文件的已核准數值。
