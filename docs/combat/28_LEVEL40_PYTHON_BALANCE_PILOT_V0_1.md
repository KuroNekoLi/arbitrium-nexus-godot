# 28 — Level 40 Boss Python Balance Pilot v0.1

> 日期：2026-10-15。狀態：**PYTHON PROTOTYPE EXECUTED / NOT GODOT ENGINE TESTED / CONTENT_PROVISIONAL**。
> 規格來源：Library `25_STARTER_PARTY_CARD_CONTENT_V0_2.md`、`26_UNIVERSAL_BASIC_MAGIC_AND_STARTER_DECK_V0_3.md`、`27_LEVEL40_DEMO_BOSS_ENCOUNTER_V0_1.md`，以及更高優先權的現行 Combat Rules。排除舊 GDD、舊 Counter-Function。

## 1. 這次實際執行了什麼

- 在本對話容器中執行 Python 3 的**獨立簡化平衡模擬器** `astraea_demo_python_sim_v0_1.py`，不是透過 Godot CLI 或正式 CombatDomain 跑的測試。
- 同一組 `seed=0..99` 分別執行四種策略：`balanced`（混合）、`aggressive`（偏輸出）、`defensive`（偏生存）、`casting`（偏詠唱）。共 **400 場**，最長每場 **24 個玩家回合**。
- 初始資料：蓮 HP1500 MP8、朱音 HP950 MP14、紬 HP1200 MP12，Boss HP3000；每角12張獨立卡池，各自起手4張、Player Phase 補至4；全隊 BaseAP=6；三人 MP 獨立且不自動回滿；Boss 行動三階段、HP傷害公式 `K=200`、物理命中率、`±5%` 候選傷害浮動、火系/奧術候選修正等。
- 有簡化處理的基本普攻回 MP、攻擊/治療/Barrier、護盾有效期、可中斷的 Boss 蓄力、詠唱、有限的 Exposed/Break、Last Spell、Guard/Protect。
- 可執行同 seed+相同策略重現的結果相等；結果輸出 CSV／示範 event trace。

## 2. 400 場第一輪結果

下表「完成率」指**24 回合內擊敗 Boss**，不是已驗證的正式玩家勝率，也不表示淘汰了玩家。

| 策略 | 24回合內完成 | 完成場次的中位回合 | 所有場次平均回合 | 戰後平均全隊剩餘HP | 每場平均治療量 |
|---|---:|---:|---:|---:|---:|
| Balanced | 100/100 | 15 | 14.77 | 2780 | 1612 |
| Aggressive | 100/100 | 13 | 13.01 | 1619 | 958 |
| Defensive | 98/100 | 21 | 20.93 | 2307 | 2176 |
| Casting | 100/100 | 16 | 16.09 | 2272 | 1192 |

`defensive` 兩場未在24回合內完成，並**不是角色陣亡**：seed 24（剩 Boss55 HP，隊伍2165 HP）、seed42（剩 Boss8 HP，隊伍1674 HP）。因此不要把 98% 誤判為 2% 的失敗死亡率。

### 2.1 職能與機制實際使用觀察

| 策略 | 蓮場均對Boss有效傷害 | 朱音 | 紬 | Break場均次數 | Boss 詠唱中斷場均次數 | Last Spell成功釋放場均次數 | 一般 Full Chant成功場均次數 |
|---|---:|---:|---:|---:|---:|---:|---:|
| Balanced | 933 | 1664 | 403 | 0.02 | 0.69 | 0.41 | 0.00 |
| Aggressive | 1192 | 1267 | 541 | 0.00 | 0.67 | 0.00 | 0.00 |
| Defensive | 533 | 1980 | 486 | 0.01 | 0.87 | 0.00 | 0.00 |
| Casting | 903 | 1783 | 314 | 0.01 | 0.68 | 0.43 | 2.25 |

- Balanced 下僅 2/100 場真正觸發 Break，僅16/100場至少建立一次 Exposed；Aggressive 分別0/100、8/100。這是**目前卡池與 AI 策略組合的使用率觀察**，不是證明 Break/Exposed 本身數值不合理。
- 三種非 Casting 策略沒有使用一般 Full Chant，因為目前是策略 heuristic 的結果，而非 Godot 施法系統被判定沒有價值。必須先改良策略，再對比施法的成功率與收益。
- Aggressive 平均以13回合完成，而且仍100/100通關；在此原型中 Boss 威脅不足，與「忽略防護應承擔顯著風險」的設計目標相距甚遠。
- 四組的通關時間中位數都未達示範戰鬥設定的6～10回合目標。

## 3. 原型具體限制（重要）

**此版本不能宣稱符合全部已核准 Combat Rules**，因為：

1. 使用的只是人工寫出的幾組選牌策略 heuristic，**並非真正玩家操作，也不是會搜尋最優解的AI**；選擇卡牌能力可能嚴重偏差。
2. **尚未執行玩家每階段免費棄1抽1**、所有抽棄牌事件/卡片效果、完整可重播 event queue，也尚未涵蓋全部卡牌邏輯與狀態優先級。起始牌組可能發揮不出其設計能力。
3. `Reaction SP`（R05/T05）僅視為手牌佔位，**未實作卡牌 Reaction Queue 與正式 trigger / skip revalidation**；基本 Guard/Protect 則為簡化模擬。對應正式測試必須由 Godot 引擎執行。
4. Break/Exposed 的部分觸發、連攜判定、Full Chant 的 Focus Ward、Buff 到期、AOE分段、DoT及 Last Spell 二次失衡細節是**內容／事件簡化版**；正式引擎不能以此 Python 原型行為作為 Source of Truth。
5. 測試只包含單 Boss 及一個候選 fixture；沒有裝備、成長曲線、真人學習操作、導覽畫面或 UI 時序。
6. 24回合 cutoff 將「未完成」列為 0，**不得誤作戰敗／陣亡**。策略經驗、命中、抽牌與 Boss Intent 的數據只代表這個 Python 版本的 RNG、AI 和簡化引擎。

## 4. 下一步優先修正

1. **先完善模擬器 fidelity**：實作免費換牌、Reaction SP 真正窗格和隊列、多段事件、卡牌效果時限、明文施法／Exposed/Break 與真正已核准的事件時序；對照 Library 20/21/27 oracle 測試。
2. **再衡量與改良 player policy**：至少 `break_first`, `exposed_combo`, `manual_interrupt`, `cast_support`, `survival`, `damage_rush`；每組相同100 seeds。另記錄卡手、各卡上手／使用率、RP 浪費和無法使用原因。
3. **只有在策略與規則一致後再調 Content 數值**：Boss HP/攻擊/特定Phase、角色輸出倍率、Break成本與詠唱收益。否則現在直接調高Boss攻擊來壓勝率，可能只是在補償原型的漏洞。
4. **落地 Godot 對照**：以相同 seed、裝備／Actor 資料、Boss fixture、command tape 檢查每項合法性與最終狀態；本 Python 結果只當平衡方向參考，不能視為 Godot 已 PASS。

## 5. 交付與狀態

- `astraea_demo_python_sim_v0_1.py` — 第一版獨立平衡 Python 程式。
- `astraea_lv40_100seeds_4strategies_v0_1.csv` — 400場結果，含 seed、policy、24回合內完成與否、回合數、角色輸出、治療、Guard/Protect、Break、Exposed、Boss interrupt、Last Spell。
- `astraea_lv40_sim_summary_v0_1.json` — 本次4組摘要。
- `astraea_lv40_seed0_trace_v0_1.txt` — balanced, seed0 的簡化戰鬥紀錄。

結論：**Python 模擬已確實執行，並得到可重現的400場首輪數據；正式 Godot 模擬、規則一致性測試、UI真人驗收尚未執行。**