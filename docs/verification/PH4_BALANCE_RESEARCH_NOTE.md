# P4.6 可重現多策略研究工具

狀態：`IMPLEMENTED_NOT_VERIFIED / BALANCE_PROVISIONAL`。本階段只交付 driver 與 tests；依使用者指示等 Main 明確通知 Lv40 API ready 後才執行對局。沒有正式平衡核准、真人 playtest、CI、commit 或 push。

2026-10-15 准入：工作區 `C:/Users/user05/Documents/Codex/2026-10-14/referenced-chatgpt-conversation-this-is-an`，起始 HEAD `5103e40a4b95da82f2561b29c2604e9514fd398b`，remote `KuroNekoLi/arbitrium-nexus-godot`；既有其他 Agent 修改保留。Godot executable 為 `C:/Users/user05/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe`，實測 `4.7.2.stable.official.ed1daf0bf`。project features 4.7、gl_compatibility、既有 SceneTree runners；`scripts/check_godot.py` 不存在，不能當可用 runner。

已讀 AGENTS、專案內 QA/Combat SKILL.md、兩套 Spec Guardian、QA_CI_STANDARDS、CARD_COMBAT_STANDARDS，以及 COMBAT_SPEC_INDEX、COMBAT_IMPLEMENTATION_CONTRACT、00/01、相關 02–09/11–13、18–23、25/26/27/29、P4_TASK_CONTRACT；實讀 M5 entry、M5.5 driver、M2 payment、M3 phase/reaction、M4 casting 與開發中的 Lv40 API。QA 技能促使保存分層證據和最多三次 attempts；Combat 技能促使逐筆 M5 dry-run、原子拒絕與完整 replay，沒有改 Canon。

## 範圍與來源對映

| Requirement | Source / authority | Implementation / case | Evidence |
|---|---|---|---|
| P46-MATRIX | 27 §10.2、25 §13.2、29 §3–5 / 研究候選 | 四策略各100相同 seeds；P46-SEED-01、P46-MATRIX-01 | TEST_WRITTEN |
| P46-ATOMIC | 22 §2/§5、12 §3 / 工程契約 | probe/commit；P46-ATOMIC-01～03 | TEST_WRITTEN |
| P46-REPLAY | P2-D16、13 RNG-001、27 DEMO-13 | 同 initial/config/tape 每步及終局完整 hash；P46-REPLAY-01～04 | TEST_WRITTEN |
| P46-REACTION | CORE-04、P1-D15/16、20 PRE3-R04 | policy 明確 Queue → Confirm 或 Pass；同 M5 重驗 | IMPLEMENTED_NOT_VERIFIED |
| P46-RESOURCE | M-D08/09/19、13 §4 | 保留 AP→RP；實付事件帳本、不用淨 HP/MP 差值代替費用 | IMPLEMENTED_NOT_VERIFIED |
| P46-METRIC | 25 §13.2、26 §7、27 §10.2 | P46-METRIC-01～07、CSV/JSON；缺欄位保留 null/NOT_IMPLEMENTED | TEST_WRITTEN |
| P46-CAP | 22 §5.4、12 §5 / 工程防護 | 24 rounds、1200 commands、16000 events、50000 probes；P46-CAP-01/02 | TEST_WRITTEN |

依使用者限定寫入範圍，對映放本 Note；RTM、Domain、UI、CI、project 和其他測試未由本 Agent 修改。

## API 對接與待補欄位

必需 API：`res://scripts/domain/m5/lv40/lv40_encounter.gd` static `config()/initial(seed)`，唯一 `M5.apply(state, command, config)`；目前使用 A/B/C/Boss、標準 U/R/A/T definition IDs、M5 envelope 的 `core.battle`、`core.cards`、`phase`、`enemy_cursor`、`enemy_actions`、`active_enemy_action_id`、`reaction_window`、`event_seq`、`events`。每步有 command_id/expected_event_seq；沒有傷害／治療數值 payload。

已讀到開發中的 `initial(seed)` 要求正整數，因此最終固定樣本 **1–100**（四策略一致），取代最初提出的0–99；不把非法 seed 0 混入勝率分母。卡牌只提交 `PLAY_LV40_CARD`；casting_mode CHANTLESS/FULL、combo_mode NORMAL/COMBO。普攻、換牌、Last Spell 和 phase/reaction 都沿用既有合法命令。Reaction SP 的 entry kind 是既有 `REACTION_SP_FIXTURE`，須實際持有 R05/T05 並由 Lv40 註冊內容提供效果；名稱含 fixture 不代表可以輸入任意效果。

精確統計的觀測欄位：

- `SPCostReservedOnly.details`：actor_id、ap_paid、ap_borrowed、mp_cost；`BasicAttackResourceCommitted`：ap_paid；`ReactionResourcesCommitted`：rp_paid/mp_paid。解包 core_event.event，避免外包裝重複計算。
- `HPHealed`：目前有 amount/before/after，足以記有效治療。**需要 `requested_amount` 才能精確記 overheal**；目前未補時輸出 null 與 `NOT_IMPLEMENTED:REQUESTED_HEAL_NOT_EXPOSED`，CSV 輸出 NOT_IMPLEMENTED。不從卡面候選倍率猜補血量。
- `DamageTrace`：recipient_id、barrier_absorbed；HPBarrierAbsorbed：target_actor_id/absorbed。我方盾實吸收和 Boss 盾吸收分開。
- CastingStarted/Released/Interrupted/Cancelled、LastSpellCommitted/Released/Invalidated/DestabilizedDelayed/DestabilizedWeakened、FocusWardGranted。Boss 中斷獨立於我方 completion/interrupt 分母；無開始的比率為 null。
- config content_version/m5_lv40_content_version、Battle ruleset_version/rng.algorithm。缺少合法術式或配置時保存 NOT_IMPLEMENTED 的 capability/rejection 原因，不能冒稱該功能通過。

API 檔案已在並行施工期間出現，**尚無 Main API ready 通知**。需要在 ready 後再確認 API、事件命名與 schema 沒有後續變動。

## 策略與統計定義

四策略都是離線研究 heuristic，不是玩家 controller；沒有 Node、UI、時間觸發、自動控制真人 Reaction。排序只用當前狀態與穩定 ID，不使用 dry-run 所抽到的未來傷害/命中/RNG 結果挑最佳牌。候選逐個以同 M5 深複本 dry-run；選定後再次 apply 並比對完整結果，只有 accepted command 入 tape。拒絕須保持完整 State（含 RNG/排程/事件/費用）與空 emitted events；commit 後執行既有 M2/M4/Zones validators。

| Strategy | AP reserve | 偏好 |
|---|---:|---|
| BALANCED | 2 | 缺血治療、MP 回復、攻擊/Break/Combo 與防護 |
| AGGRESSIVE | 1 | 朱音即時輸出、finisher、後續 Last Spell；優先基本 Guard |
| DEFENSIVE | 3 | 治療、Barrier、較多 RP；仍有輸出且受回合上限約束 |
| CAST_SUPPORT | 2 | 朱音 Full/Last Spell、其他人 U03/Barrier、合法 Protect |

reserve 是研究選擇，不是新的 Domain 行動限制。Focus Ward 已達8時不反覆堆疊；Barrier 已有餘量不重複無效補盾。免費換牌僅在無值得執行的候選後，選不可主動使用的手牌並讓 M5 驗證；不直接改 hand 或 RNG。24回合含第24敵方階段，不進第25玩家階段釋放法術。

卡手採「每個可行動角色在每個 Player Phase 首次決策時，非 Reaction SP 沒有任何合法主動出牌」/該角色階段樣本數；逐卡同時記 samples/dead。合法性包含當前 AP/MP/目標/狀態，**不把 reserve 過濾當成非法**；另記 reserve_limited_candidates 與零 MP 樣本。Reaction cards 排除主動卡手分母，並保留實際卡使用／事件 coverage。這不是抽牌本身品質的獨立因果估計，也不外推真人勝率。

研究 outcome 為 win/defeat/timeout/error；timeout 是 driver cap，沒有改 Domain outcome，也沒有 UI 反應倒數。保留所有結果分母100，另報勝利回合 p50、全部回合 p10/p90、Wilson 95% 勝率區間、HP/AP/MP/治療/盾/施法/卡手總量。配置候選值沒有被改動或升格 Canon。

每場 JSON 包含 initial/config/final、accepted tape、完整 emitted events、每步 state/event hash、decisions、rejection reasons、失敗 command、metrics、event/state/tape/config/initial/full-event hash；timeout/error 也 replay accepted prefix。同 initial/config/tape 每步與終局皆完整比對。Matrix 的 attempt metadata 記實際 Git HEAD、Godot 完整版本與 Domain/資料 SHA256；執行前後查 source 變更，避免並行編輯污染研究而仍報成功。

## 執行方式與證據

目前只執行 Godot `--check-only --script res://tests/test_lv40_balance.gd`，不匯入或執行遊戲。解析日誌：`outputs/p4_logs/lv40_balance_parse_attempt1.log`（第一版，exit0，無 SCRIPT ERROR）、`outputs/p4_logs/lv40_balance_parse_attempt2.log`（最終程式版本，exit0，無 SCRIPT ERROR）。本解析群組共2次，未使用第三次。限定路徑的 `git diff --check` exit0；新檔仍未提交，不能把它當成完整 runtime 或 CI Gate。

測試程式預設只執行22個政策／統計／輸出範圍 assertions，並明示研究 NOT_EXECUTED；加 `--lv40-api-ready` 才執行額外12個 API/原子拒絕/cap/replay/矩陣 assertions 及400場完整研究，每場再完整 replay。**本交付執行數：0 tests、0 games、0 replay；沒有將 check-only 計入 assertion PASS。** CI NOT_EXECUTED；故意失敗 probe NOT_EXECUTED；M1–M5 回歸 NOT_EXECUTED。舊 M5.5 fixture 100 wins 和 Python400/12000研究都沒有拿來填入 Lv40 結果。

Main 明確通知 ready 後，可由 workspace 執行（PowerShell，將下列 `$lv40Godot` 設為上方實際 executable）：

```powershell
& $lv40Godot --headless --path . --script res://tests/test_lv40_balance.gd -- --lv40-api-ready --output=res://outputs/lv40_balance_attempt1 2>&1 | Tee-Object -FilePath outputs/p4_logs/lv40_balance_attempt1.log
$lv40Exit = $LASTEXITCODE
```

每場輸出到 `outputs/lv40_balance_attempt1/<STRATEGY>_<seed>.json`，同目錄有 games.csv、attempt.json、summary.json。目錄必須未存在；最多使用 attempt1/2/3，跨 outputs/outputs/p4_logs 累計。每次失敗保留原 logs/JSON，不覆寫或換名重置執行次數；不可將研究成功與正式平衡核准混稱。每個新增 scene/player controller 不得引用本工具。

限制：所有 runtime cases 仍 TEST_WRITTEN；overheal 待 Domain 提供 requested_amount；四策略未經實際研究校正；沒有真人驗收；沒有改數值、補造未實作術式、fixture秒殺或提交。最終審查、Domain Gate、CI 和唯一 commit/push 由 Main 負責。

## 2026-10-15 — Parallel Balance metrics package delta（本包工作分支）

**IMPLEMENTED_NOT_VERIFIED / NOT_EXECUTED**：本次在 `handoff/p4-balance-research-chat-20261015` 基於共同 WIP 基底，僅新增 `tools/balance/lv40_research/metrics.gd`、`tests/test_p4_balance_metrics.gd`，並在既有 `lv40_godot_policy.gd` 把全部100個seed×4策略的 `outcome` 交給統計 helper。原Domain依賴仍未審核合併，**沒有執行400場**。此前本研究 note 的 parse-only 兩次嘗試屬歷史基準，不能當作這輪的證據，也未清除記錄。

新 pure API：`Metrics.distribution(samples)` 拒絕 NaN/INF、非數值和負樣本情形要由上層定義；可處理空/單筆、mean/median/p95/peak（線性插值）。`Metrics.wilson95(wins,trials)` 對非法總數回 null，不把無試驗資料報零勝率。`Metrics.paired(by_seed,strategies,expected_seeds=100)` 檢查每組 same-seed 的 outcome 配對；win/defeat/timeout/error 都納入，輸出同勝、單方勝、全不勝、timeout/error及paired delta。缺seed／缺策略 → `complete=false`；driver正式矩陣若不完整 → `ERROR_INCOMPLETE_PAIRED_MATRIX`。各策略新增 `round_distribution` 與 `winning_round_distribution`，空集合保留null。原始逐場JSON／CSV及 Replay／State hash 不變；不改Boss/卡牌候選值、不誤接真人Controller。

新增可獨立跑的 `tests/test_p4_balance_metrics.gd`：統計sample邊界、百分位數、Wilson CI、timeout/error包含在paired分母、缺配對與非法outcome拒絕。實際Godot版本、test output、exit code、CI/run URL、400場replay hash：**NOT_EXECUTED**。待Godot 4.7.2 checkout：`godot --headless --path . --script res://tests/test_p4_balance_metrics.gd`；接Domain審核整合commit再執行 `test_lv40_balance.gd -- --lv40-api-ready`（既有群組attempt不得重置）。

Android/Kotlin對照：對同一Seed做paired experiment類似性能比較中的同一輸入AB測試；失敗與timeout不能被不透明filter掉。面試追問：為何不用成功場次做分母？（selection bias）；為何Wilson而非Wald？（小樣本與0/100邊界）；為何指標與Domain分離？（可重用、純函式、Replay穩定）。替代：Bootstrap paired CI需實測資料與更高研究成本，現階段保留提案不假稱實作。
