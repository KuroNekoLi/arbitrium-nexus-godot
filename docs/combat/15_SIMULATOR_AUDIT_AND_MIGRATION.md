# 15 — v0.7.1模擬報告審查、歷史規格遷移

> **Documentation status · 2026-10-15 — HISTORICAL_EVIDENCE**：v0.7.1 報告、8-card/Prepared Deck/舊 RP 限制等僅顯示遷移歷史，不是現行 Canon、最新 Godot CI 或新平衡批准。 先讀 [Combat Spec Index](COMBAT_SPEC_INDEX.md)；目前未驗證項目見 [Open Issues](COMBAT_OPEN_ISSUES.md)。**M1～M5.4 1,081 項 Domain CI 有證據，M5.5 仍未驗證。** 舊正文的「當時狀態」僅供歷史追溯，不得升格為新核准或新 CI。


## 1. 原始測試證據（不是Canon）

來源：Library `貼上的文字 (1)(3).txt`，Godot 4 deterministic simulation，seed `20261014`，Boss 600HP，上限8回合。

| 策略 | R8 Boss HP | 雙人連攜次數 | Last Spell |
|---|---:|---:|---|
| 基準 | 140 | 0 | 無 |
| 雙人連攜 | 134 | 5 | 無 |
| Last Spell | 38 | 0 | 一次延遲、Yura Exhausted |
| 共鳴Last Spell | 17 | 0 | 無延遲、Yura Exhausted |

所有戰術8回合都未擊敗。**不可推論真實玩家勝率/最佳連攜策略**：Boss意圖腳本固定、只攻擊Yura、原型數值、單seed。

## 2. 已確認與最新設計不一致的地方

1. 模擬 Combo `Astral Flame Blade` 額外扣1 AP，**新基線已確認0額外AP**；並且模擬部分由單張Expose直接產生雙人連攜傷害，缺真正第二名角色的合格卡牌出牌事件。
2. 同角多次普通攻擊後多次回MP，與「每人每回合首次回魔」方向相悖。
3. 模擬 Focus Ward 同時減HP傷害與干擾；新設計要與 Barrier 分開，複合效果須明示。
4. 模擬 `carried RP` 跨回合，與 P1-D09 正式決議（當回合剩餘AP全轉RP、敵方階段結束歸零）相衝突，**必須修正**。
5. 模擬器每角8 MP、普攻回1，早期討論有6 MP、回2，應列候選，而非擅自升級為Canon。
6. Last Spell後Yura已Exhausted仍被攻擊及被隊友Reaction保護，這是目前未決的TargetPolicy，不一定bug但必須先決策。
7. 模擬卡牌 Full Chant Stability 2 vs對話設計示例20/34等級相差大，缺角色Casting Resilience差異與干擾倍率。
8. 現有報告沒有不同seed／多種策略玩家決策、命中／閃避、死亡/復活、UI實測，不能代表平衡。

## 3. 原始 repo文件的有意識遷移

歷史 `COMBAT_SYSTEM.md` 與 `Life_RPG_Astraea_GDD_v1.1.md` 的 Spell Card 的術式媒介、戰鬥理念、Last Spell 敘事等不必刪除，但其 `Prepared Deck = 6, No Random Draw` 被新的 `12 Cards per character + draw to four` 正式取代；舊的 Main/Quick/Individual-turn 需經由01記錄衝突，只有被核准的部分才轉換成共享AP流程。

Agent不應直接覆蓋整份舊世界觀文件；應為其補「已由 v0.8 SoT 替代的章節」索引，必要時另開PR，對未決系統維持TBD。使用者未授權的原始 repo 不得假稱已同步。

## 4. 修正順序（推薦）

- P0-1：確立此整套規格為 repo 首要 reading entry（README/AGENTS.md 指向00）。
- P0-2：將連攜變真正的雙卡、雙角色、0額外AP 交易並新增契約測試。
- P0-3：修正普通攻擊回MP次數；移除RP跨輪儲存與2RP硬上限（P1-D01/LEGACY-Q09）。
- P0-4：建立雙防護層及角色Casting Resilience/Disruption屬性。
- P0-5：完成 Exhaused/HP0/命中/時序 P0決策後，再實作正式 Boss loop。
- P1：多seed重跑四策略和不同MP經濟、輸出分佈；報告移除單場結論誇大。

## 5. 正式交付與證據邊界

本資料夾提供工程交接規格，不代表已修改Godot/GitHub專案或已執行模擬器。每當Agent執行修正，必須附commit/測試指令、實際測試結果、對應的replay檔及適用版本。


---

## 6. Phase 1 實作遷移清單（已核准行為／待重做模擬）

| Migration ID | v0.7.1 或舊文行為 | v0.8+P1 正式期待 | 對應測試 |
|---|---|---|---|
| MIG-P1-01 | 只存2RP，無法保留剩餘6AP | 玩家階段末所有剩餘AP→RP，正常0..6 | P1-ECO-004/005/006 |
| MIG-P1-02 | RP 帶至下輪 | 敵方階段末一律RP=0 | P1-ECO-007/008 |
| MIG-P1-03 | 同人多次普攻重複回MP | 該人當玩家回合首次成功普攻才回MP | P1-ECO-001/002 |
| MIG-P1-04 | 每窗口只能使用一張特殊Reaction | 同窗口每人實際一次，多位角色可響應 | P1-RXN-005～008 |
| MIG-P1-05 | 沒手牌就不能守 | 基本 Guard/Protect 常駐，分別1/2 RP | P1-RXN-001～004 |
| MIG-P1-06 | Protect缺守護者防禦重算 | 單體物理魔法由守護者防禦抗性計算 | P1-PRT-001～005 |
| MIG-P1-07 | 混合護盾處理HP與干擾 | Barrier/Focus Ward獨立；命中附干擾可隨Protect轉移、direct casting disruption不可 | P1-PRT-006～008 |
| MIG-P1-08 | 逐張反應彈窗或效果先扣費 | 玩家預先排順序一次確認，失效未執行的後序反應免耗 | P1-QUEUE-001～009 |
| MIG-P1-09 | 強制單一Reaction UI策略 | Smart預設、Always Ask/Quick只影響UI | P1-QUEUE-010～012 |
| MIG-P1-10 | 舊Combo附加1AP/憑空額外攻擊 | 真正雙卡兩角，Combo 0額外AP | COMBO-002/003 |

### 6.1 隔離的數值與重測要求

Guard率40%、原始傷害50、角色承傷45/30、魔法干擾15、Casting Stability20、BossHP600、MP max6/8等均為**PROVISIONAL / TEST FIXTURE**；可用來驗證正確計算次序，卻不能輸出「平衡已證明」「Best build」之類結論。每次多seed重測需連同commit、rules_version、完整策略輸入、遇到的boss敵方行動次數、Reactions實際發動/失效跳過次數、RP消耗/未使用比率、Guard防禦收益、Protect轉移傷害等統計一併輸出。

### 6.2 版本驗證門檻

- `v0.7.1` 的固定 seed 報告**不再是Phase1行為回歸的PASS依據**；引擎移植需用 `v0.8+P1` 更新Replay命令結構、保留新舊期望差異。
- 文件同步與GitHub push成功，只說明**規格已交付**，不代表Godot引擎、Boss AI、UI或實機已更新。
- 若任何檔案在 GitHub與Library版本不同，標記為不同步；以01裁決為基準逐項核對。資料與測試證據不能互相替代。