# 29 — Astraea Level 40 Chapter Boss：卡牌 RPG 參考研究、Python v0.2 與平衡結果

> **Documentation status · 2026-10-15 — PYTHON_RESEARCH_V0_2 + BALANCE_PROVISIONAL**：Python v0.2 的測試和建議數值是研究證據，不是 Godot parity、Domain 正式戰鬥 100 seed 或使用者正式平衡核准；26 的 UNIVERSAL v0.3 起始牌組仍是內容候選。 導覽：[Combat Spec Index](COMBAT_SPEC_INDEX.md)；未決：[Open Issues](COMBAT_OPEN_ISSUES.md)。M5.5／完整可玩驗證尚未完成。以下保留來源快照，不能解讀為此刻最新驗收。


> 日期：2026-10-15 · **PYTHON PROTOTYPE TESTED / BALANCE PROVISIONAL / GODOT NOT EXECUTED**
> 依據：Library `/docs/combat/00–28` 最新有效 Combat Rules；`25` 角色與卡牌、`26` 通用魔法與起始牌組、`27` Lv40 Encounter、`28` Python v0.1 報告。
> **不引用 Life_RPG_Astraea_GDD_v1.1.md／舊 Counter-Function。** 此文件不修訂 USER_APPROVED 的 AP、RP、MP、詠唱、Break、Exposed、Last Spell 與勝敗核心契約。

## 1. 其他卡牌 RPG 的 Boss 回合節奏：可證據化的部分

| 參考 | 已查證資訊 | 應採取的設計判斷 | 來源 |
|---|---|---|---|
| Slay the Spire — Time Eater | 官方／Wiki有固定「HP 低於一半的一次 Haste」，隨行動卡數累積壓力；**沒有可據此推算所有玩家平均回合的資料** | 把 Boss 強招、節奏窗口與 HP階段設計為玩家可見且可反制 | https://slaythespire.wiki.gg/wiki/Time_Eater |
| Slay the Spire — Hexaghost | 玩家社群討論常以高回合數的強攻期限作戰力檢測；具體值因版本與難度而異 | 對拖延策略設戰術壓力，不把所有防守玩法強制斬斷 | https://www.reddit.com/r/slaythespire/ |
| Across the Obelisk | 其部分 Boss 有回合計時的 Doom，玩家可用特殊牌延長生存期限；玩家回饋可在強力配牌下2–3回合處理某些 Boss，屬**個別回報非平均統計** | 在 Boss 核心曝露與蓄力處理上製造反制價值 | https://steamcommunity.com/app/1385380/discussions/0/3181237564268433747/ |
| Darkest Dungeon / 2 | 玩家對一般路途戰表示約2–3回合，另有 Boss 15 回合的個人經驗；不同戰鬥**不可混成平均** | RPG 隊伍戰鬥輪數跨度大，應從「每輪實際操作時間」校正 | https://www.reddit.com/r/darkestdungeon/comments/yqpo9a/ ; https://www.reddit.com/r/darkestdungeon/comments/16r8org/ |

**研究結論：** 未找到可靠的跨遊戲「章節 Boss 平均回合數」樣本分布，不能宣稱平均一定是6、8或10。針對本作三名角色、每人12卡、共享6AP、回合內操作密度，提出 **標準玩家中位8–12 Player Phases**；熟練高傷策略6–9、保守12–16。這些是**本作設計目標**不是外部遊戲實測平均。真人 QA 應另測一輪操作秒數，理想整場約12–20分鐘，並非已驗證指標。

## 2. 審計 v0.1 找到的關鍵錯誤（先修正才談平衡）

原 `astraea_demo_python_sim_v0_1.py` 在 `damage` 函數中，以 `actor` 字串分辨攻擊者／防禦者，但玩家攻擊呼叫 `damage(player_id,...)` 卻拿**玩家自己的 PDef/MDef**代入減傷；敵人攻擊則拿防守者的 Accuracy 參數作命中來源。故第一版 400 場的回合數僅能當舊模型記錄，**不可當角色／Boss 的真實傷害平衡結論**。

v0.2 修改了攻守來源：玩家打 Boss 使用 Boss PDef/MDef／玩家Accuracy／BossEvasion；Boss 打隊員使用 Boss Accuracy／目標Evasion／目標PDef/MDef。`K=200`、±5%浮動、暴擊、命中與 FIRE/ARCANE 倍率仍依 `27` 的候選設定；並新增可配置 `boss_hp`、`boss_attack_factor`、`break_max`。

### v0.1 vs. 修正傷害後 v0.2：相同原始 Boss 規格（HP3000，攻擊×1，Break30）

| 策略 | v0.1 24回合內完成 | v0.1 完成中位回合 | v0.2 24回合內完成 | v0.2 完成中位回合 |
|---|---:|---:|---:|---:|
| 均衡 | 100/100 | 15 | 100/100 | 13.0 |
| 進攻 | 100/100 | 13 | 100/100 | 9.0 |
| 防守 | 98/100 | 21 | 100/100 | 19.0 |
| 一般詠唱 | 100/100 | 16 | 100/100 | 15.0 |

**注意**：兩個版本除了修正公式，也在免費換牌與 Reaction SP 近似模型上不同；此比較用於解釋「先前關於降 Boss HP 的判斷失準」，而不是嚴格的單因素公式實驗。

## 3. Python v0.2 實際執行範圍

- 自本輪 Library 保存的 v0.1 程式獨立修正並擴充為 `astraea_demo_python_sim_v0_2.py`（可執行）。
- 每角色12卡、開手4、補至4、最多8；新增**每角每回合最多一次免費棄1抽1**簡化路徑，阻止同一 CardInstance 當次立即抽回；抽牌及棄牌實例守恆。
- 每回合共享 BaseAP6、個人MP持續、基本普攻恢復MP、RP→基本 Guard/Protect；新增初步 R05/T05 的手牌/RP/MP 檢查與一次窗口擋傷／反擊；FocusWard 與 HP Barrier 分開存量。
- Boss 3 Phase／B01–B11 候選循環、Charge 下一回合才釋放、A05合法打斷與 B10 冷卻、B11 Break fallback、有限 Exposed 後續 SP 利用／雙人 A06 Combo、一般 Full Chant、Last Spell committed→release/HP0 invalidated 的**近似模擬**。
- 15 組參數 × 8 種出牌 heuristic（balanced、aggressive、defensive、casting、break_first、exposed_combo、cast_support、last_early）× 100 固定 seeds (0–99) = **12,000 次**；比較時各情境每策略的 seed 相同。
- Python smoke test **11項 PASS**：同Seed結果相同、36卡區域守恆、自己防禦不誤當Boss防禦、敵方使用目標防禦、免費換牌不抽原卡、Reaction無資源不能用、R05合法窗口、Focus Ward吸 Stability 干擾、Last Spell 釋放前倒地失效、Boss蓄力不立即攻擊、Break fallback不跳過。

**不是形式上的完整 Domain 引擎一致性通過：** React 多人提交後二次重驗、全量事件 queue/order、Last Spell 延遲／二次失衡減弱、所有 DoT/Buff精確到期、ComboOpportunity完整狀態、含策略本身的公平性、Enemy Intel、真實存檔 replay hash 均未完成。R05/T05只有可執行**簡化反應**；完整迭代仍須在 Godot 實作。這是人工作成的策略 heuristic，不能外推真人勝率。

## 4. 候選平衡 v0.2：以既有 Lv40 角色資料不變、調 Boss 數值

優先推薦 **候選 A**，**不是最終核准**：

| 內容參數 | v0.1 | 候選 A | 說明 |
|---|---:|---:|---|
| Boss MaxHP | 3,000 | **2,700** | 原 3,000 太冗長，縮短回合但保留3階段 |
| Boss 攻擊乘數（Python限定） | 1.00 | **1.70** | 模擬器的傷害係數；Godot需資料表明訂 PAtk/MAtk 改版，不要重複乘1.7 |
| Break Gauge Max | 30 | **22** | 增加與劍技的互動機會，但仍需起始牌組／Boss CORE_OPEN 改善 |
| Boss PDef/MDef | 90/85 | 90/85 | 不變 |
| Boss Barrier P2 | 180 | 180 | 不變 |
| Boss Casting Stability | 9／15 | 9／15 | 不變 |
| Fire／Arcane | ×1.15／×0.90 | 不變 | 不自動移植到其他敵人 |
| 我方Lv40全能力及卡牌 | 依25/26 | 不變 | 不直接對朱音／紬亂加傷害；避免多因子混淆 |

此時 B06 超載光束打朱音未防禦的**中心傷害**會從約420 增至約714；強招應顯示新估計值，並實測 Guard→Barrier、Protect及是否造成過度急遽死亡。B09 對全隊亦須重算UI估傷。`attack_factor` 只為Python參數，Agent不應直接把它當 Combat Rules 公式的新常數；若要在 Godot 固化，可先取 Boss PAtk 417／MAtk 434 **候選整數**，再依同 seed 重跑驗證對照。

### 推薦候選 A — 100 seeds × 8策略

| 策略 | 24回合內完成 | 完成中位回合 | 至少1角色 HP歸零的場次 | 平均 Break/場 | 平均 Exposed實際利用/場 | 平均 Reaction SP/場 | 平均一般 Full Chant完成/場 |
|---|---:|---:|---:|---:|---:|---:|---:|
| 均衡 | 100/100 | 12.0 | 9% | 0.31 | 0.07 | 1.89 | 0.00 |
| 進攻 | 100/100 | 8.0 | 35% | 0.63 | 0.18 | 0.00 | 0.00 |
| 防守 | 97/100 | 18 | 68% | 0.54 | 0.18 | 2.67 | 0.00 |
| 一般詠唱 | 100/100 | 14.0 | 22% | 0.32 | 0.12 | 2.30 | 1.94 |
| Break 優先 | 100/100 | 11.0 | 8% | 0.78 | 0.11 | 1.41 | 0.00 |
| Exposed / Combo | 100/100 | 11.5 | 3% | 0.24 | 0.15 | 1.53 | 0.00 |
| 詠唱支援 | 93/100 | 16 | 98% | 0.58 | 0.11 | 0.00 | 1.98 |
| 早期 Last Spell | 100/100 | 11.0 | 12% | 0.77 | 0.26 | 0.00 | 0.00 |

**注意區分：** 完成率代表24回合內將 Boss HP 降至0，不等於全員無傷且不等於真人勝率。部分 KO 場最後仍成功擊敗 Boss；同時全員HP0的法定勝敗僅按已核准完整合法事件邊界結算，本程式在特殊事件上仍不足以代替 Domain oracle。`aggressive` 雖35%場次至少倒地一名角色，但100/100場仍通關；因此「激進打法有一定風險」已初步呈現，但**尚未滿足原先希望通關率65–85%的難度目標**，不能宣布完成平衡。

- 這組數據中 `balanced` 中位12回合、`aggressive` 8、`break_first` 11、`exposed_combo` 11.5、`last_early` 11；符合首輪回合範圍的**部分**測試目標。
- `defensive` 中位18回合且97/100場於24回合內完成；防守型顯得拖沓，應先改善策略避免無意義的過量治療。
- `casting` 中位14回合、`cast_support` 中位16回合且93/100完成，顯示完整詠唱支援策略目前不具效率優勢；可能是高成本、詠唱風險或 heuristic 失誤。
- `break_first` 平均 Break 0.78次/場，仍不足以確保新手自然看見一次 Break；`exposed_combo` 每場成功利用 Exposed 0.15次，且真實 Combo 罕見，**必須再設計一條可達成教學的可重播固定初始牌序／合法操作，不可 UI 硬塞卡**。
- `last_early` 明確在首個玩家階段就提交朱音 Last Spell，可達成100/100候選樣本釋放；**這只檢查刻意觸發，不代表一般玩家應在開局使用終極技**，且完整 Last Spell 失衡仍未模擬。若高傷試驗過強，需測投入成本、Exhausted行動機會損失。

## 5. 分工與品質門檻（給下一階段 Godot Agent）

**這一輪完成**：閱讀 Combat Rules、修正 Python 模型、15組參數同 seed 測試、11 個 Python smoke test、產出可重跑的程式／逐場CSV／JSON／sample traces／候選 Fixture 與交接契約。

**未通過、不得宣稱完成**：正式數值平衡驗收、所有事件機制完整支援、完整 Reactive Queue、所有狀態規則、Godot headless / CI PASS、UI真人試玩、正式角色等級成長曲線。

**下一階段 Agent 優先工作**：嚴格比對 Library 00–28 的 Source of Truth → 先把 v0.2 候選 Fixture 轉成 Godot可解析 Definition → 完成 Domain replay oracles（13/20/21/27）→ 用同100 seeds驗證 Godot vs Python 分歧 → 在合法玩法下再微調 content 數值 → 可玩的3v1示範戰鬥；不要讓 Python 近似實作覆寫 Combat Rules。

## 6. 同步狀態與交付

- 此文件是新的 **29號平衡研究與Python測試報告**；候選平衡資料存在獨立 JSON。
- Godot Agent 開發交接另見 **30號文件**，已包含檔案位置、已完成／待補驗收與禁止事項。
- 沒有改動舊 Library `00–28` 的 USER_APPROVED 原文；沒有推 GitHub、沒有在 Godot 執行、沒有宣稱 CI PASS。