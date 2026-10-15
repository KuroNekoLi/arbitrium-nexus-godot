# 23 — Astraea Phase 3：Godot 戰鬥引擎五階段實作計畫與 Gate

> **Documentation status · 2026-10-15 — HISTORICAL_EXECUTION_PLAN + APPROVED_MILESTONE_SPLIT**：首段 `PLAN ONLY / NOT IMPLEMENTED` 是 2026-10-14 原計畫截面；M1～M5.5 已完成 Headless Battle/Fixture 範圍的正式驗收。M5.1～5.5 的正式工作包拆分不變。 先讀 [Combat Spec Index](COMBAT_SPEC_INDEX.md)；目前未驗證項目見 [Open Issues](COMBAT_OPEN_ISSUES.md)。**M1～M5.5：1,238/1,238 Domain assertions；100 場固定 Seed 完整戰鬥與 Replay 已通過 [Master CI #38678649741](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38678649741)。Godot Scene／真人可玩／正式平衡仍未驗證。** 舊正文的「當時狀態」僅供歷史追溯，不得升格為新核准或新 CI。


> **日期：2026-10-14｜狀態：PLANNED / NOT IMPLEMENTED / NOT TESTED。** 本文件是 Codex 分階段開發任務書；**不表示 Godot 專案已存在、測試已通過、UI 已完成**。玩法來源只來自現行 `docs/combat/00`～`21`，本文件不重新制定戰鬥規則。先讀 `AGENTS.md` 與 `22_PHASE12_AGENT_IMPLEMENTATION_CONTRACT.md`，任何歷史 `DRAW`、Last Spell 死後續唱、強制 Reaction 倒數等提案都已被 USER_APPROVED 最新裁決取代。

> **四項最新版決策 ID**：`CORE-01` 同時終局玩家勝；`CORE-02` Last Spell 施法者生效前 HP0 即強制失效（取代舊 `PRE3-R15`）；`CORE-03` 不走位／可使用 2.5D；`CORE-04` Reaction 無秒數自動 Pass。`M-D21` 雙模式同 MP；`M-D25` 手牌上限8/基本補4。

## 0. 執行策略與進度表

**目標**：先建立可重播、無 UI 依賴的回合制戰鬥 Domain Engine，最後以可執行正反測試驗證戰鬥完整鏈。**工作單位一次只執行一個 Milestone**（M1～M5），每個 M 中只處理已指定的工作包，不預先「順手做完」後續整個階段。

| Gate | 階段 | 主要輸出 | 狀態（此文件建立時） |
|---|---|---|---|
| **G0** | 環境查核／規格對映 | 真正的 Godot repo、Godot 4 binary/version、commit、RTM baseline、測試入口規畫 | `NOT STARTED` |
| **M1** | Domain Model / Command / Event / State Machine | 純資料戰鬥狀態、合法命令、交易式結果、seed/replay 骨架 | `NOT STARTED` |
| **M2** | AP / MP / RP / Card Zone / Free Swap | 共享資源、Overload／債務、獨立牌庫與換牌 | `NOT STARTED` |
| **M3** | Player & Enemy Phases / Guard / Protect / Reaction | Sequential player actions、敵方意圖與 Reaction queue JIT | `NOT STARTED` |
| **M4** | Chantless / Full Chant / Casting Interrupt / Last Spell | 延遲詠唱、退款、失能強制取消與 Exhausted | `NOT STARTED` |
| **M5** | Hit / Damage / Status / Combo / Exposed / Break / Outcome | 固定傷害流水線、Boss 行動、完整 Domain battle、Replay suite | `NOT STARTED` |

**各 Gate 的嚴格定義**：`SPEC_ONLY`=已定文件但程式不存在；`IMPLEMENTED_NOT_VERIFIED`=程式存在但缺真測試／任一必測失敗；`BLOCKED_*`=找不到環境/資料/核心決策；`VERIFIED`=本階段實際測試加回歸全部成功且有 log/seed/version/commit。**M5 VERIFIED 不等於完整 UI/2.5D 可玩。**

### G0 — 真實專案辨識（沒有它不能開始編碼）

1. 查看目前 repo 的 `README.md`、`project.godot`、`git status --short`、`git rev-parse HEAD`、實際 Godot binary。已知 `KuroNekoLi/astraea-combat-rules` 是**docs-only repo**；切勿在這裡猜出 `res://tests/run_all.gd` 或強行初始化 Godot。若 Godot 專案在另一個 repo，必須拿到**使用者指定／已獲授權**的路徑或 repo 才能繼續。此時將根 `AGENTS.md` 複製或做適當繼承到實際程式碼庫（需保留來源路徑），並留存版本來源。
2. 在真實 Godot repo 確認 Godot **4.x** 小版本、OS/環境、`.godot` 和 scene 資產、GDScript 語法、CLI 是否支援 `--headless` / `--script`、既有測試框架，以及 CI 有無配置。不可偷偷替使用者更新主引擎小版本。
3. 建立 `requirements_traceability.md`（規範見22），**枚舉 `13` 中所有現行 Test ID**（包括已被後來 User Approved 取代的歷史預期），每項標：適用 M1～M5、`SUPERSEDED`、`DEFERRED_CONTENT` 或 `BLOCKED_FIXTURE`，沒有遺漏空白行。每項新的程式功能必須追溯真實 requirement ID；不可用「Phase 2 大致符合」取代證據。
4. 設計或採用 Test Runner，所有示例 Godot CLI 執行前都需要先確認真實檔案存在。建立最小故意失敗 fixture，證明 Runner fail exit 非0；再執行正例證明 exit=0。若沒有現成 runner，**M1 包含建立 runner**，G0 先只記錄 runner 建立方案。
5. 記錄 G0 輸出：`SOURCE_SPECS_COMMIT`、`GODOT_CODE_REPO`、`CODE_COMMIT`、`GODOT_BIN`、`GODOT_VERSION`、`GODOT_PROJECT_DIR`、`RUNNER_PLAN`、`RTM_VERSION`、`OPEN_BLOCKERS`。

**G0 停止條件**：找不到 Godot 程式碼庫、無修改權限、不確定 Godot 版本、現有 source modified 且無法安全歸因、缺必要規格權威；當場標 `BLOCKED_ENVIRONMENT`，不寫程式、不偽造測試，也不以初始化 docs repo 代替。

## 1. 共用工程品質規約

### 1.1 分層與資料正確性

- Domain 以版本化 `BattleState`、`Command`、`Result`、`DomainEvents` 和 `SeededRNGState` 互動。事件只由域內 reducer/resolver 產生，UI 以 Signal 消費，**不得**由 UI 自行扣資源或決定勝敗。
- 固定事件序：`phase_id`、`action_id`、`window_id`、`card_instance_id`、`casting_instance_id`、`event_seq`；相同輸入與 seed，事件序列與 state hash 必須完全一致，與 FPS / renderer / 2.5D 無關。
- 執行器應對命令做 validate-before-commit；拒絕時回傳具體錯誤碼而不改任何狀態或 RNG。資源值不能非法負值，Overload debt 是獨立非負欄位而不是 AP 穿透成負數。
- 實際可調值集中於 `ruleset_version` / `provisional_balance` 與逐卡 `ContentConfig`。`MaxAPDebt=8`、Guard40%、首次普攻 MP+2、Full Chant MP部分退款50%、MaxMP 6/8/12、±5% 傷害浮動都只是**候選測試值**；不得宣稱已核准永久固定。
- player-facing 字串使用 i18n key；靜態型別 GDScript 4.x；可讀註解重點是高風險分支的規格 ID，而不是每個簡單 setter 都註解。

### 1.2 通用測試命令（**範本；須等 runner 真實存在且驗證後才能執行**）

```bash
# Read-only environment checks in the actual Godot project:
"$GODOT_BIN" --version
test -f "$GODOT_PROJECT_DIR/project.godot"
test -f "$GODOT_PROJECT_DIR/tests/run_all.gd"
# Once the agent has implemented and smoke-tested this runner:
"$GODOT_BIN" --headless --path "$GODOT_PROJECT_DIR" --script res://tests/run_all.gd
# Repo-local scripts, flags or test filters MUST be discovered; do not assume a --suite switch exists.
```

Tester 需實際設定 CLI process exit code，exit非0→ Fail；測試記錄要有 `spec_commit`, `code_commit`, `Godot version`, `ruleset_version`, `content_version`, `seed`, `initial_state_hash`, `command_tape`, `event_hash`, `final_state_hash`, `cases executed/passed/failed/skipped`, `runtime errors`, `timestamp`。Phase 3 並非可以用伪造固定日志來滿足規格。

### 1.3 每群組修復限制

對每個 failing test group **最多3次執行（首次 + 兩輪修復測試）**。第三次仍失敗→立刻停止當前 Milestone，保存每次差異與原始輸出，回報原因，禁止透過弱化斷言、把「已核准規則」改寫為「程式現在做的」來通過。只有經使用者同意才能開新的嘗試輪次。

## 2. M1 — 核心 Domain Model、命令與可重播交易

**依賴／先決條件**：G0 完成、實際程式碼庫確認、規格版本固定。

### M1 逐步實作（每項為可驗收小工作包）

1. **M1.1 型別定義**：建立 Actor/Battle/Phase/Resource/CardInstance/CastingInstance/Status/EnemyAction/Target/Outcome 模型（視 GDScript 選擇 Resource / RefCounted / class_name，禁止將 Scene Node 直接序列化為權威狀態）。定義合法範圍、必填 `id`、stable order、深複製語義。
2. **M1.2 Command & Validation**：`SelectActor/BasicAttack/PlaySP/EndPlayerPhase/QueueReaction/ConfirmReactions/PassReaction/Analyze` 等命令 **data shape** 與通用拒絕碼先定；未做完的 Resolver 可回 `FEATURE_NOT_IMPLEMENTED` 而非假執行。`Last Spell`/牌區細節在 M4/M2 才執行。
3. **M1.3 Transactional reducer**：`validate → commit costs/effects → append events → state transition`，拒絕時 state/hash/RNG unchanged；Phase 序不可被非法命令跳過。設置 domain-only PRNG adapter（狀態可保存/回放）與種子使用政策。
4. **M1.4 Test harness**：建立 `tests/run_all.gd` 或既有框架的等價接口；能單獨跑 fixture、顯示 case IDs，驗證故意失敗 fixture 能造成 non-zero process exit。支持 deterministic replay 的 `snapshot + command tape + expected events/hash` schema，先寫最小 smoke tests。
5. **M1.5 RTM+工程筆記**：更新實際程式碼 repo 的 requirement/source/test mapping，列出未實作功能並標 `DEFERRED_TO_M2..5`。

**必測 Oracle**：非法 ActorId、無效 Phase、過期 action 命令被拒絕且不扣資源／不消耗 RNG；同 seed+commands 事件穩定；成功/失敗 runner exit code；無 Node/FPS 時 Domain 仍可運行；同 actor 可以在後續 M3 的模型中多次行動（M1 不擅自建總隊預排限制）。

**測試對照**：`RNG-001`、`P1-ECO-002/003`（其中 M1 僅原子拒絕與事件模型部分）、`P2-REPLAY-01`（骨架 smoke，完整 M5）、`P2-VIS-01`（Domain 與畫面依賴性靜態檢查）以及新 `PH3-M1-CMD-001～005`（細化測試 ID 與固定 fixture）。

**DoD**：Godot 4.x headless runner 真實可用且 exit 行為正確；state/command/event 序列化可重播、非法命令原子性通過；至少一個固定 seed replay 通過；沒有聲稱 M2～M5 尚未提供的功能已完成。缺真 CLI 證據→`IMPLEMENTED_NOT_VERIFIED`。

## 3. M2 — 行動資源、個別牌庫、換牌與 Overload

**依賴／先決條件**：M1 `VERIFIED`，同 seed/command/state 可追溯。

### M2 逐步實作

1. **M2.1 AP/MP/RP**：隊伍共享 BaseAP6，但 `CurrentAP` 合法無 cap；每人 MP/MaxMP 個別記錄，無自然回魔；首個**合法成功執行的普通攻擊**每角每 PlayerPhase 回 MP 一次，量從 provisional config；EndPhase AP→RP 且受有效 cap 限制、EnemyPhase 結束歸零。
2. **M2.2 成本引擎**：M-D01～M-D17：原子 cost validation、依特性折扣/SetCost（PRE3-R10）、Overload 明文 tag 才能借缺額、同回合 AP refunds 進 CurrentAP 而不自動清 AP debt、跨期 debt M-D04 僅測試候選、需提供 0 AP PlayerPhase 測試。
3. **M2.3 Cards/Deck**：每角色 12 張 SP 的身份（
`CardInstanceID`）、draw/hand/discard/casting 的唯一所屬；初始手4、Phase start 若不足4才補足、未用保留、最多8；任何 failed draw 不會捏卡、洗牌遵循 seeded RNG。Analyze 是獨立命令，Last Spell 獨立槽。
4. **M2.4 Free Swap**：每角色每 PlayerPhase 1 次，0 AP/MP；有合法替代牌的 precheck、CardInstance 防立刻抽回、**棄牌事件及 trigger 先於新抽牌事件**；沒有可換卡 precheck 失敗不扣次數；合法啟動後牌庫被棄牌 trigger 改變而 draw failed（PRE3-R11）時不回滾先前合法事件，保留完整 log。
5. **M2.5 invariant & replay**：卡牌區 instance count 守恆、行動成本沒有部分扣費、RP 不跨 EnemyPhase、MaxMP 不上溢、AP debt 只按已決機制還款、無 0 AP 無限抽牌／回費閉環。

**主要測試 IDs**：`DECK-001～004`、`ECON-001～003`（考慮合法 Overload 例外）、`P1-ECO-001～009`（舊 `P1-ECO-009` 的 `BLOCKED_BY_DECISION` 歷史敘述須以 M-D08 生效 cap6 覆寫）、`M18-AP-001/002`、`M19-MP-001`、`M20-MP-002`、`M25-HAND-001/002`、`M26-SWAP-001`、`M27-SWAP-002`、`M29-SWAP-003`、`M30-SWAP-004`、`M31-MP-001`、`PRE3` 的 swap/debt/oracle（從13掃描實際 ID）。

**反例／邊界**：持手牌4補0；持7額外抽3只抽1；沒有合法替代牌換牌拒絕且不發事件；換牌棄牌觸發抽卡改變可用池；先花AP再發額外AP >6；超過RP cap截斷不誤帶下一回合；AP不足且無Overload時整筆拒絕、MP0不可付費、MaxMP過量恢復只截斷不存溢出；卡牌已在 CastingZone 不能再抽。

**DoD**：資源及牌區 invariants 真實 PASS、所有本階段 mandatory case 有可重播日志、跨回合/長卡手/延遲換牌情境穩定，其他模組仍清楚標 deferred。沒有真程式碼與 Godot logs 不可報 M2 DONE。

## 4. M3 — Player Phase、Enemy Phase、Guard／Protect／Reaction Queue

**依賴**：M1～M2 已 `VERIFIED`；可使用設計 fixture 代替未建完整 Boss AI 的資料，不得以 fixture 偽稱最終 Boss。

### M3 逐步實作

1. **M3.1 Phase engine**：Player Phase 一次選一 Actor 一筆命令立即合法結算；可以 A→A→B→A；完成 `EndPlayerPhase` 才轉敵方階段；Phase start 依 PRE3-R09 tick → outcome boundary → AP debt/refresh → refill hand4。獨立敵人行動 ID 與穩定排序。
2. **M3.2 Reaction Window**：敵方宣告 Action 後，若有合法 Reaction 才開窗；UI可 Preview/Queue/Reorder，確認前不可扣費，Confirm 後以玩家順序逐筆 JIT 驗證、扣 RP/MP、解決；失效後續 `ReactionSkipped` 不付費、不占已執行配額。
3. **M3.3 Guard / Protect**：Guard 1 RP、只對該 EnemyAction 的合格多 hit 生效；Protect 2 RP、只能守護合格單目標，**先轉向再判命中**；同個 EnemyAction 第一個成功 Protect 取得重導向權；Protect 不免費減傷、不承接 direct CastingInstance Disruption；命中型 status 若附 `follows_damage_recipient` 先重驗。
4. **M3.4 UI mode 等價**：Domain 不設 countdown；Smart/Always Ask/Quick **只改呈現**。只要有合法 Reaction，必須等待明示 `Confirm` 或 `Pass`。UI FPS /動畫速率沒有時間來源。無合法 Reaction 可跳過空窗。
5. **M3.5 Replay + regression**：多段 Guard、多人 Protect、RP cap、不同 EnemyAction 的窗口配額不共用，角色死亡時排隊反應 skipped 無費。

**主要測試 IDs**：`P1-RXN-001～010`、`P1-ECO-003/004/007/008`、`REACT-001/002`、`P2-RXN-01/02/03/04`、`P2-VIS-02`（不能新增走位 Domain Command）、`PRE3-R01～R05/R17` 與13中同主題 PRE3 Test IDs；須額外做 `PH3-M3-PROTECT-001`（命中在轉向後）、`PH3-M3-QUEUE-001`（前序取消攻擊後後序免費 skipped）。

**關鍵反例**：同人同窗口排 Guard+Protect 不得雙付；A反制取消 Boss 行動後B Protect 不扣費；AOE/多目標 basic Protect 禁止；沒有RP的Queue不能Confirm後部分扣費；Exhausted/Incapacitated 不能付反應；二次同 window 提交拒絕；Quick 等120秒不會 timeout/autopass。**不替 M4 編造真正 Casting interrupt 效果**，可用 cancellation fixture 模擬觸發，M4再驗真實整合。

**DoD**：可以無畫面跑完 Player/EnemyPhase+Reaction 的一組完整序列；event log可追蹤每筆 queued/paid/skipped；三種 UIMode 同輸入 state hash一致；回歸 M1～M2 真通過。人類可操作 UI 尚不是 M3 的 Domain DONE 條件。

## 5. M4 — 雙詠唱、法術干擾與 Last Spell 倒地強制失效

**依賴**：M1～M3 已驗證；能宣告 EnemyAction 與 Reaction Window。

### M4 逐步實作

1. **M4.1 Chantless & Full Chant**：同 SP 兩模式預設相同 MP 消耗；提交時 AP/MP扣費一次。Chantless 即時合法效果；Full Chant 放 CastingZone/Concentration，建立 `CastingInstance`，按明定 event clock 到期，不可提前造成傷害、不因UI動畫提早結算。
2. **M4.2 Casting Disruption**：敵我 `Casting Stability` 與 Boss Break 分離，FocusWard 只吸收干擾；合法普通 FullChant `CastingInterrupted` 即時退**可配置部分 MP**，AP/Overload不退；主動取消、施法者HP0、已釋放Spell Counter 各需不同 reason，不可退款混用。
3. **M4.3 Last Spell**：獨立技能槽、每名角色每戰一次、FullChant-only、提交前二次確認、提交後不可主動 Cancel。普通 Disruption 首次可延遲、再次依明文削弱，**不能默默變成普通法術直接取消**；稀有度/削弱比例仍在 provisional content。
4. **M4.4 USER_APPROVED HP0 強制失效**：釋放前 caster HP 變0→`ActorIncapacitated`→`LastSpellInvalidated(CASTER_INCAPACITATED)`→`ScheduledEffectCancelled`；到期沒有任何原待效傷害，即使 Revive 也不恢復；已付 AP/MP/Overload 和 once-per-battle 不退。**已合法釋放完成**的法術，施法者在後續必要事件才HP0不得追溯抹除傷害。最後效果成功釋放 → Exhausted，仍可受敵攻擊與治療但不能新動作。
5. **M4.5 Regression**：CastingZone 卡牌實例唯一，事件到期次序可重播，Reaction/Protect 能合法保護集中施法者，直指 CastingInstance 的干擾不被轉向，Combo/Resonance細節保留逐卡配置。

**主要測試 IDs**：`CAST-001～005`、`LAST-001～005`、`P2-LAST-01～06`、`P2-CAST-01/02`、`M21-CAST-001`、`M22-CAST-002`、`P1-RXN-009/010`、`P2-D12-001`（FocusWard），`PRE3-R12/13/14/15`。

**特別驗收腳本（必做）**：

```text
Seed = known; caster=A; boss=B
T1: A 提交 Last Spell，生效點 T3；記 AP/MP 已扣、once_used=true。
T2: B 讓 A HP=0；當下應觸發 Incapacitated、LastSpellInvalidated、ScheduledEffectCancelled。
T2+: A 被 Revive（如 fixture 允許），仍不可重開原 LastSpell；再嘗試主動 Cancel 一律拒絕。
T3: 不可出現該 LastSpell 的 MagicDamage/ApplyDamage event。
Opposite: caster 未死且只被普通干擾 -> 專屬延遲/削弱；不可像一般 FullChant 一次干擾就 Cancel。
```

**DoD**：上述正反例、跨回合及 replay 真通過；Casting Interrupt MP refund 與 HP0 forced invalidation 的 events/type 嚴格不同；M1～M3 回歸通過，Last Spell 削弱數值若仍 provisional 如實標記。未通過禁止做 M5 的「完整魔法戰鬥通關」宣告。

## 6. M5 — 命中、傷害、狀態、Boss、Break/Exposed/Combo 與勝敗

**依賴**：M1～M4 均有真實驗證結果。

### M5 逐步實作

1. **M5.1 Hit/Crit/Damage**：區分必中/需命中/條件傷害SP，百分比線性命中、一般 5–95% clamp，Accuracy/Evasion、PAtk/PDef 或 MAtk/MDef 的既定公式、seeded variance、eligible crit（CritRate 與 CritDamage可獨立養成）、敵人自訂元素抗性。`Guard` 在 `Barrier` 之前生效，最終一次取整（floor0 是 delegated engineering default）；傷害 trace 記每次中間結果，不以缺乏真數值推定遊戲全面完成平衡。
2. **M5.2 Status/Targeting**：Status 有 `stack_policy`、時效/tick與priority，Buff/Debuff/DoT/Barrier/FocusWard 逐個配置；Protect after-target semantics；Incapacitated 不能一般主動命令、不能被普通治療自動復活；Exhausted 可受治療但不能主動行動。
3. **M5.3 Boss/Break/Exposed/Combo**：Boss Intent 依已選行動忠實預告；Exposed 只有符合SP可用且有效期；Break 在**整張SP結算完成後**替換下一合法尚未開始 BossAction 為 `BreakFallbackAction`，非永久暈眩；不同角色可以建立/終結 Combo，必須支付兩張卡自己的成本，Combo不憑空額外扣一次AP。
4. **M5.4 Outcome USER_APPROVED**：每個 Action 及其已承諾的合法事件完成後，**先查最後敵人是否全滅 → VICTORY，即使全隊HP0**；否則若我方全部失能但敵人仍存活 → DEFEAT；不得硬編 DRAW。和 M4 Last Spell 的釋放前 HP0 取消要共同測試；已釋放成功後的同 action 雙方死亡按 VICTORY 處理。
5. **M5.5 Full battle fixture & replay**：建立一組**明示 PROVISIONAL / FIXTURE_ONLY** 的3角各12SP＋1個Boss encounter、少量個別狀態/BreakFallback／Combo。完整從初始化→Player Phase→Enemy Phase→Reaction→Casting→Break／勝敗運行可重播；不同 FPS/2.5D presentation mock 相同 command tape 不影響 Domain。

**主要測試 IDs**：`P2-D10-001`、`P2-D11-001`、`P2-D12-001`、`P2-D13-001`、`P2-D14-001`、`P2-D15-001`、`P2-D16-001`、`P2-OUT-01/02/03`、`P2-REPLAY-01`、`P2-VIS-01/02`、`BREAK-001`、`COMBO-001～004`、`RNG-001` 與13之全部 relevant P2-S PRE3 回歸 cases。

**壓力／屬性測試**：至少100 seeded runs **屬工程基準**（不是保證數值平衡成功），隨機合法 Action/Reaction，確保無負資源、無卡實例重複、無非法HP0後施法、反應不可強制timeout、同 seed hash 恆一致。任何資源回饋循環都不能讓引擎死鎖；回放還需驗證 command tape 包含角色/卡片instance、時序版本、content版本。

**DoD**：真實 CLI headless 完成一個具合法勝敗結束的完整戰鬥、所有既有 M1～M4 回歸與 M5必測均PASS、同 seed replay匹配、錯誤報告具追溯／log，沒有永久定死平衡候選。**這仍是 Domain Engine Gate，不等於可玩UI、2.5D美術或商業內容已完成。**

## 7. M5 之後：Presentation Spike 與可玩 Gate（明確排除五步範圍）

- 在 Domain 完整驗證後，分別做極小 Presentation Spike：方案A `Node3D + Sprite3D`、方案B `Node2D + Y-sort`；比較 Camera / 觸控 HUD 佔比、卡片與角色易讀性、遮擋/特效、Godot 4.x 技術風險、Android FPS 與開發維護成本。**暫不替使用者做唯一 2.5D 技術選型**，不影響任何 Domain Tests。
- 再做卡牌可視化、Intent、Casting/Reaction 佇列、2.5D/2D battle presenter、音效、美術、英中 i18n；先保證 Smart/Quick **無限時強制略過**。呈現層從 Event 產動畫，不反向決定 HP/MP/勝敗。
- **可玩 Gate**：人工連玩至少1場、記錄操作與EventTrace，將錄影／截圖與實際 Domain 結果對照；測試手機不同 FPS、文字語系與輸入設備。真實角色/卡牌/Boss資料完整並通過平衡審核後才可稱 PLAYABLE VERIFIED。

## 8. Codex 單步執行 Prompt（可直接貼）

```text
你是本專案的 Godot 4.x / typed GDScript 戰鬥引擎 Tech Lead。
先遵循專案 AGENTS.md、docs/combat/22_PHASE12_AGENT_IMPLEMENTATION_CONTRACT.md
與 docs/combat/23_PHASE3_EXECUTION_PLAN.md，並讀完整規格與本步涉及的決議及驗收案例。

當前只執行【G0 + M1】（如 G0 已驗證，則只 M1）；不要預先做 M2～M5。
先回報真實 Godot code repo、project.godot、Godot binary/version、Git commit 與工作區狀態；
如果現在只有 astraea-combat-rules 規格庫而沒有 Godot 專案，停止程式實作，
只交付可追溯的 M1 任務包與 MISSING_GODOT_PROJECT blocker，不得臆造測試通過。

為本步建立 Requirement ID→來源文件章節→實作檔案→測試 ID 的 RTM；
先寫 Positive/Negative/Boundary 和適用的 EventOrder/Replay 測試，再寫最小實作；
實際執行 Godot headless 測試、回歸測試，記錄 CLI、exit code、seed、版本、log、hash。
每個失敗群組最多初測一次+修復重測兩次。第三次仍失敗立即停下，
不可刪測試/弱化斷言/改Canon自救；提供原因與保留的git diff。

只有所有本步 Gate 都有實際執行證據才報 VERIFIED，否則報 BLOCKED 或
IMPLEMENTED_NOT_VERIFIED。完成後列出下一步，但不要自行開始下一步。
```

## 9. 最終交付與核對檢查表

每個 milestone 完成時必須提供：source spec commit（規格庫 SHA）、code repo commit、具名 Requirement IDs、受測 Test IDs（含實際 tests executed/passed/failed/skipped）、Godot executable+版本、可重跑 CLI/exit、seed/command tape/ruleset/content版本、event/state hash、影響的程式碼檔案、PROVISIONAL 值表、實際 evidence 路徑（可供下任 agent 存取）、剩餘 blocker、下一步 Gate。**不要把 Library／GitHub 文件已儲存，誤當 Godot 引擎已實作成功。**

## 10. G0 Godot 專案定位與 M1 工程交接（2026-10-14）

原建立本計畫時僅能確認 `astraea-combat-rules` 是文件庫，但後續已找到真正的 Godot 專案：**`KuroNekoLi/Astraea-Academy`** `main` 分支，`godot/project.godot`（Godot 4.7 / README 4.7.2），原有 `godot/tests/foundation_test.gd`。因此 M1 原始碼應提交到 **Astraea-Academy**，而不是把 `project.godot` 塞進本規格庫。

最新 M1 程式／規格交接、設計比較、測試指令、CI 與 `NOT EXECUTED / VERIFIED` 條件見 `24_PHASE3_G0_M1_EXECUTION_REPORT.md`。**在真實 Godot 4.7.2 CLI 與原測試成功執行並留下 log 之前，M1 僅為 `IMPLEMENTED_NOT_VERIFIED`，M2 不得開始。** 請以程式庫 `docs/verification/PH3_M1_ENGINEERING_NOTE.md` 的實際測試證據判斷是否升級 Gate，不可以本計畫舊的 `G0 NOT STARTED` 快照取代新查核結果。


## 11. G0/M1 已取得實際 Godot CI 證據（2026-10-14）

程式庫 [KuroNekoLi/Astraea-Academy](https://github.com/KuroNekoLi/Astraea-Academy) 已建立 Phase 3 M1 Domain scaffold。CI [run 38548346979](https://github.com/KuroNekoLi/Astraea-Academy/actions/runs/38548346979) 在 **Godot 4.7.2 stable** 真正執行 **14/14 M1 cases PASS**、故意失敗探針 exit17 與原 Foundation regression PASS。程式碼已測版本 [a8c96b8](https://github.com/KuroNekoLi/Astraea-Academy/commit/a8c96b8ed83d334a2818642e3e83ea3266a2a0f7)；詳細 hash、命令與缺口見 `24_PHASE3_G0_M1_EXECUTION_REPORT.md`。

**目前 Gate：G0 VERIFIED / M1 SCAFFOLD VERIFIED；M2～M5 未開始。** 此段是先前「G0 不得假設已有 Godot 專案」的後續實際查核，不代表 2D/2.5D 可玩介面、勝敗或卡牌資源已完成。下次另行授權 M2，仍必須先讀原規格並實測 M1 回歸。