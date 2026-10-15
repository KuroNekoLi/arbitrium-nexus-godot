# 30 — Astraea Lv40 Demo Boss：Godot Agent 後續交接規格（暫不執行）

> 日期2026-10-15｜HANDOFF READY / NO GODOT EXECUTION / NO GITHUB PUSH。**本文件只供未來Agent啟動時使用**。除非使用者另指令，請勿現在啟動Godot、實作畫面或推送 GitHub。

## 0. 任務入口

在既有 Astraea/Godot 專案中完成**一場Lv40三人對秘紋守衛・零式的可玩 3v1 示範戰鬥**。不新增職業/抽卡商業邏輯/自由走位/第二 Boss。這不是重寫整個遊戲的需求；先檢查既有 repo 的 CombatDomain 與 Phase3 M1–M5 已完成程度。

## 1. 資料優先順序，嚴禁混舊版

1. 最新明文 USER_APPROVED 決策。
2. Library `/docs/combat/00_README_COMBAT_RULES_BASELINE_V0_8.md` 導覽以及 01–24 最新有效戰鬥規則。
3. `/docs/combat/25_STARTER_PARTY_CARD_CONTENT_V0_2.md`：三角色、基礎 stats、card定義、LastSpell、Combo。
4. `/docs/combat/26_UNIVERSAL_BASIC_MAGIC_AND_STARTER_DECK_V0_3.md`：新 UNIVERSAL U05、起始三副12卡、T09/T10定義（覆寫25的舊deck配置）。
5. `/docs/combat/27_LEVEL40_DEMO_BOSS_ENCOUNTER_V0_1.md`：Boss B01–B11、敵特定元素、Intent/Phase/Exposed/Break、測試 oracle。
6. `/docs/combat/28_LEVEL40_PYTHON_BALANCE_PILOT_V0_1.md`：舊400場 Python prototype，**內含已發現傷害計算錯誤，不得直接當Godot正解**。
7. `/docs/combat/29_LEVEL40_BOSS_PYTHON_V0_2_RESEARCH_AND_BALANCE_REPORT.md`：Python v0.2 的修正與12,000場敏感度分析；全部內容數值 **BALANCE_PROVISIONAL**。

**禁止**引用 `Life_RPG_Astraea_GDD_v1.1.md`、舊 `COMBAT_SYSTEM.md`、`Counter-Function` 來取代新版規則。區分 `Casting Disruption`/`Spell Interrupt`/`Spell Counter`，以及 `Break` vs `Exposed`；Analyzer不消耗卡片，不製造Break/Exposed。

## 2. Godot 導入的候選數值：不要暗中核准

`demo_level40_balance_candidate_v0_2.json`：Boss HP2700、模擬攻擊倍率1.7、BreakMax22、Boss Barrier180，其餘v0.1 fixture未變。這是**內容候選，不是核心規則變更**；建議Godot落地時轉成 PAtk/MAtk（暫估417/434）且跑一致性驗證，別重複乘以1.7。

Level40隊伍：朝霧蓮 swordsman、九條朱音 burst mage、白石紬 healer/support；每人獨立12卡、都可配置U01奧術彈/U02魔力屏障/U05初階治癒術；MP個人、BaseAP6隊伍共享。Last Spell獨立槽且成功後Exhausted，釋放前HP0立即Invalidated。角色未來變職只能經已解鎖Variant，不提供戰鬥中即時切職。

## 3. Godot Agent 分階段執行建議

- **G0 / Audit**：對照目前repo Phase3 M1–M5已存在之domain能力與測試證據，**保留已通過的正確邏輯**；列出Gap，不得依舊版v0.1自己防禦誤植公式。
- **G1 / Content Validation**：將25/26/27/29/JSON候選轉為Godot ContentDefinitions; 遵守稳定ID+zh-TW/en i18n；ValidateLoadout檢查12張、各實例ID唯一、UNIVERSAL資格合法、Variant卡合法。
- **G2 / Domain Regression**：按13/20/21/27驗證 AP/RP、免費換牌、先事件再判勝負、Reactions queue+重新驗證skip、FocusWard/Barrier、雙模式Full Chant、Boss Intent公開鎖定與pending spell、BreakFallback、Exposed合法單次利用、Combo真出2卡、Last Spell中斷延期/二次弱化和HP0強制失效。
- **G3 / Determinism & Balance**：固定seed=0–99、四類以上策略、完整command tapes與StateHash；輸出Godot與Python差異比對，差異應以最新Combat Rules為真而非回頭遷就 Python heuristics。重測3,000/2,700 HP與Break30/22。不得跳過真實補牌、Reaction Queue。
- **G4 / UI/UX**：橫向2D/2.5D三角色HUD、中央Boss、公開Intent/Break/核心裸露/Casting條，下方單次只顯示一人手牌與卡詳情；三人中文／英文顯示，技能與角色名稱不照抄 UI 參考圖。
- **G5 / Playtest**：1場親自操控可通關，展示U05基礎治療、至少1合法Reaction、1次Boss Charge對策、1次 Exposed→另一張SP利用、1次 BreakFallback、1次有真正延遲的Full Chant或Last Spell；若不能同一固定seed全展現，允許多個明文固定QA seed，各自可重播、不可硬塞卡。

## 4. 附件／可再執行

- `astraea_demo_python_sim_v0_2.py`: Python方向性模型。命令：`python astraea_demo_python_sim_v0_2.py --seeds 100 --out .`。
- `test_balance_v0_2.py`: 11項unit smoke test。命令：`python test_balance_v0_2.py`。
- `run_scenarios.py`: 同100 seeds的15×8參數掃描。命令：`python run_scenarios.py`。需要約數秒，無第三方Python套件。
- `all_scenarios_v0_2_12000_runs.csv`: 12,000場逐次結果，適合做aggregate或跨Godot比對；**不是引擎oracle**。
- `balance_scenario_summary_v0_2.json`: 每情境與策略的KPI。
- `recommended_seed_0_balanced_trace.txt`、`recommended_seed_82_balanced_trace.txt`、`recommended_seed_0_last_early_trace.txt`：簡化事件紀錄，供定位核心互動，不是Godot命令回放。

## 5. 驗收及風險警示

**不能假稱全部機制已完成：** Python原型只實作近似Reaction SP而不是完整提交佇列；FocusWard影響合法時點與失衡二次效果仍不完整；ComboOpportunity狀態、部分Status、LastSpell特別延遲/削弱均需要正式Domain。原型 24回合未通關不等於團滅。數值勝率基於人造Heuristic，真人技能選擇不同。

**驗收須輸出**：Godot CLI test logs、deterministic seeds、每次Boss事件/卡牌合法性、100種固定牌序、CI status、已知Gap、平衡差異原因、真人操作時間測試和Playtest結論。未完成仍應如實標註NOT TESTED。

## 6. 可直接貼給Agent的指令

> 請繼續 Astraea/Godot Lv40 Demo Boss，不重新規劃專案。先讀Library `/docs/combat/00–30` 最新文件及本次附帶的Python v0.2 handoff bundle；以USER_APPROVED Combat Rules為唯一權威，未授權不得改核心機制。先Audit既有Godot M1–M5，再導入Level40三人 + Boss秘紋守衛・零式之資料驅動fixture，完成合法性/事件回放測試與可玩示範戰鬥。Python v0.2只作平衡參考，不得當正式Domain oracle。請分階段提供測試證據，不要超出單Boss MVP scope。禁止使用舊GDD或Counter-Function；所有UI文案zh-TW/en不得硬編碼。