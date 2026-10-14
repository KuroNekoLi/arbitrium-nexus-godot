# 22 — Astraea Phase 1–2：Codex Agent 實作契約與需求追溯規範

> **建立日期：2026-10-14｜狀態：ENGINEERING PROCESS CONTRACT（開發流程規範），不是新玩法 ADR。** 既有 Phase 1–2 Gameplay 正式規則以 `00`～`21` 及最新版 USER_APPROVED 裁決為準。此文件只建立 Code Agent 的**工作方法、驗證義務、輸入輸出契約與交付條件**，不將尚未核准的遊戲數值／引擎配置升格成 Canon。其配套工作計畫為 `23_PHASE3_EXECUTION_PLAN.md`。

## 1. 目標、適用範圍與不可替代的規格

**產品**：傳統 JRPG ＋ 每名角色獨立 SP 牌組的戰鬥系統；2D 橫向／可使用 2.5D 表現、回合制、3 名隊友。**Phase 3 無自由走位**。開發技術目標 Godot **4.x**、**GDScript 2.0**、可獨立執行的 headless / deterministic Domain Engine。

**最重要的現況限制**：`KuroNekoLi/astraea-combat-rules` 目前為 **docs-only 規格 repository**；此處沒有 `project.godot`、遊戲 Scene、已存在的測試執行器。Codex **不得**假設此 repo 直接可以跑 Godot CLI，也不得未經授權在此初始化工程。實作前必須辨識實際 Godot repo／工作區，讀取 `project.godot` 與 Godot binary、工作樹、版本與既有測試。尚未找到時，`IMPLEMENTATION_BLOCKED: MISSING_GODOT_PROJECT` 是正確結果，文件設計本身仍可完成。

**主要規格入口**：

| 檔案（皆於 `docs/combat/`） | 角色 |
|---|---|
| `00_README_COMBAT_RULES_BASELINE_V0_8.md` | 戰鬥範圍、SoT、閱讀契約與版本衝突優先級 |
| `01_DECISIONS_AND_CONFLICTS.md` | P1 與已決衝突的來源 |
| `02_BATTLE_LIFECYCLE_TIMELINE.md` | Phase、Action／Reaction 時序 |
| `03_PARTY_ACTIONS_RESOURCES.md` | AP、MP、RP、Overload、基本指令 |
| `04_DECK_DRAW_CARD_RULES.md` | 牌區、補牌、換牌、個人牌組 |
| `05_DUAL_CASTING_AND_INTERRUPTION.md` | Chantless / Full Chant、Casting Stability 與中斷 |
| `06_BOSS_AI_INTENT_BREAK.md` | Boss、Break、Intent |
| `07_REACTIONS_PROTECTION.md` | Guard/Protect/Reaction queue |
| `08_LAST_SPELL_EXHAUSTED.md` | Last Spell、Exhausted、死亡取消 |
| `09_COMBO_SYSTEM.md` | Combo 與配合條件 |
| `10_CHARACTER_VARIANTS_COLLECTION.md` | 角色／Variant 特殊規則，不自動變成已實作角色表 |
| `11_DAMAGE_STATUS_TARGETING.md` | 命中、傷害、狀態與目標 |
| `12_ENGINE_ARCHITECTURE_EVENTS.md` | Command/Result/Event、seed、重播、保真 |
| `13_TEST_MATRIX_ACCEPTANCE.md` | **Spec oracles**：測試預期，不是 Godot 已跑成功的紀錄 |
| `14`／`15`／`16`／`17`／`18`／`19` | ADR、遷移、較早與後續批准、設計交接；19 在 Github/Library 命名不同但為同議題 |
| `20_PHASE12_PREIMPLEMENTATION_ADR_AND_OPEN_ITEMS.md` | PRE3-R01～18、DELEGATED_DEFAULT、BALANCE_PROVISIONAL；**第7節正式推翻表中舊 CORE 提案** |
| `21_PHASE2_SPEC_ACCEPTANCE_REPORT.md` | Phase 2 **文件 Conditional Pass**、P2 核心四決策、未完成清單 |
| 本文件22、計畫23、根目錄 `AGENTS.md` | 開發規範與履約過程；**不是新的遊戲玩法來源** |

**衝突優先級**：最新明示 `USER_APPROVED`（尤其 `CORE-01`～`CORE-04`） > 原核准 P1／P2／M > PRE3 `DELEGATED_DEFAULT` > `BALANCE_PROVISIONAL`／逐卡可配置值 > HISTORICAL/SUPERSEDED。版本標記不可視為「日期較新便可以自行改核心規則」。需要改已核准行為時，提出具體 `ADR` 後等待使用者授權；不可先改程式再修文件。

## 2. 不可違反的行為不變量（抽查表）

1. **玩家回合每步立即結算**：選合法角色的一個行動→驗證→扣費→立即效果/啟動詠唱→action boundary→可再選同人/他人。不要求三人預排全部動作。敵方 Reaction 是**先排隊、一次 Confirm、逐筆 JIT 驗證及結算**（02、07）。
2. **共享 AP，獨立 MP**：BaseAP=6 不是消耗硬上限；合法 CurrentAP 可以高於6；Overload 有明文標籤、折扣、跨回合 APDebt 候選機制；預設 RP cap6、Enemy Phase 後清零。首次普通攻擊才按條件補 MP，無固定自然回魔。數字候選必須保持 PROVISIONAL（03、18～20）。
3. **每名角色恰12 SP、各自牌區**：戰鬥開局手牌4；每個 Player Phase **補至4**，不用牌保留，上限8；不是每回合抽4也不是手滿8。Analyze獨立 0 AP/MP/RP 全隊每戰2次，Last Spell不占12卡/手牌（04、16、18～20）。
4. **免費換牌**：每名角色每個 Player Phase 一次、0 AP/MP；PRECHECK 無合法替代牌則不執行／不扣次數；隔離被棄 `CardInstanceID`，先真實棄牌事件及觸發，再真正抽卡事件及觸發；不能立刻抽回同一實例；M-D12 防無限連鎖（04、19、20）。
5. **雙模式同 MP 預設（M-D21）**：一張 SP 的 Chantless、Full Chant 預設同 MP cost；Full Chant 提交時扣費／到期結算；成功 Casting Interrupt **立刻退部分 MP**但 AP、Overload Debt 不退。退款比例可配置，不能偷定50% Canon（05、18～20）。
6. **Last Spell（CORE-02 覆蓋 PRE3-R15 舊假設）**：每名角色每戰一次，獨立槽，只 Full Chant，不可玩家主動 Cancel；一般干擾僅延遲/削弱；**施法者在發動完成前 HP0 → 立刻 Forced Invalidation，取消待效事件，不能死後生效、復活後不能恢復、已付費用與使用機會不還**。正常合法釋放後進 Exhausted，Exhausted ≠ 死亡（08、20§7、21）。
7. **勝敗**：一個合法 action 及必要 effects 結算完成後，**敵方全滅優先判玩家 VICTORY**，即使我方全員 HP0；敵人仍存活但我方全失能才 DEFEAT。先前 DRAW／死後 Last Spell 續唱都是被取代的歷史提案（02、08、20§7、21）。
8. **無限時／不移動**：Smart/Always Ask/Quick 的合法 Reaction 都要玩家明示 Confirm/Pass，沒有秒數倒數或自動 Pass；可做 2.5D 美術呈現，但禁止新增可自由走位指令、AP 走位費用、FPS 影響命中。已有 `range_tag`/Near/Mid/Far 僅依已核准靜態定義（07、20§7、21）。
9. **傷害與可觀測**：選擇 Actor/Target 法律檢查→依規格 Protect 轉移目標→命中→暴擊／攻防／元素→Guard→Barrier→最後取整／HP→狀態/Break/Exposed 的合法時點；Barrier 防 HP、Focus Ward 防 Casting Stability；同指令＋同 seed 同 trace。精確倍率與特殊 tag 需要逐張規格，不能照猜（11、12、20）。
10. **拒絕是原子操作**：不合法 Action 不能部分扣 AP/MP/RP、偷抽／棄卡、消耗 RNG、轉換 Actor、註冊排程事件。整個回合不允許重複卡片實例、負資源、過期 Reaction Window 二次執行。必要事件應攜帶 `instance_id`、`action_id`、`seq`，不能使用 UI 時鐘當排序來源。

## 3. Agent 實作架構與模組邊界

**建議的實作結構（不是目前 repo 已存在的路徑；由 Codex 根據真實 Godot 專案調整）**：

```text
project.godot
src/combat/domain/
  model/         # BattleState, ActorState, Resources, CardInstance, CastingInstance
  commands/      # Command typed union / IDs / validation
  resolver/      # Phase, Resource, CardZone, Damage, Casting, Reaction, Outcome
  events/        # DomainEvent + stable sequence / snapshot
  rng/           # Seeded PRNG adapter with serialized state
  rules/         # ruleset_version, provisional_balance, content configuration
src/combat/presentation/
  battle_controller.gd    # reads domain; adapts input -> command
  battle_presenter.gd     # visual 2D/2.5D; consumes results/events
  battle_signals.gd       # UI broadcast only; never calculates damage
res://tests/
  run_all.gd               # create and verify; CLI exit != 0 on failure
  fixtures/                # versioned tiny battle + seed + command tape
  test_*/                  # unit/integration/replay/property tests
```

原則：`BattleState + ValidatedCommand + PRNGState + Ruleset -> NewBattleState + DomainEvents + ErrorReason`；**Domain 決定結果，UI/Signals/Tweens 只展示**。不要將 Godot Node/Scene、OS wall clock 或可變 UI reference 存入可重播的 BattleState。Godot 4.x 靜態型別建議用在變數、函式參數、回傳值；`@export` 限設計者應於 Inspector 調整的 UI/Scene/Resource 屬性，並非所有內部數字一律 `@export`。跨模組的數值來源應集中於版本化配置。

**2.5D 選型未核准**：`Node3D + Sprite3D billboard` 與 `Node2D + Y-sort` 是兩種可比較的演出方式，應於 Domain 穩定後做 presentation spike，以手機效能、卡牌可讀性、鏡頭、遮擋及工具可維護性為標準。不得把其中一種未經分析地當正式既定方案，也不得增加自由移動。

## 4. Requirements Traceability Matrix（RTM）契約

任何改動都要在 `docs/verification/requirements_traceability.md`（建議位於**實際 Godot repo**）追蹤，每筆至少包含：

| 欄位 | 要求 |
|---|---|
| `requirement_id` | 精確 ID：如 `P1-D01`, `M-D29`, `PRE3-R13`, `CORE-02` |
| `source` | 真實規格檔名＋章節／決策 ID；不得憑空猜檔 |
| `authority` | USER_APPROVED / APPROVED / DELEGATED_DEFAULT / PROVISIONAL / TBD |
| `domain_components` | 真正存在的程式位置，不能只填建議路徑 |
| `test_case_ids` | 對應 `13` 的測試 ID 或新增且清楚對照的唯一 ID |
| `positive/negative/boundary` | 具體 Setup/Action/Expected；時序功能增加 event-order/replay |
| `evidence` | 執行命令、Godot 版本、seed、規則／內容版本、exit code、log 路徑、commit SHA |
| `status` | SPEC_ONLY / TEST_WRITTEN / IMPLEMENTED_NOT_VERIFIED / VERIFIED / BLOCKED；**不得跳級** |

### 最小追溯範例（規格案例，不是執行證據）

| Requirement | Source | Expected tests | 應檢查的結果 |
|---|---|---|---|
| `P1-D01` | `02`／`03` | `P1-ECO-001/003` + `P1-TURN-SEQUENCE-001`（新案例） | 同人連續行動與跨人交錯可行；每次 Action 即結算 |
| `M-D25/26/27/28/29/30` | `04`／`19`／`20` | `M25-HAND-001/002`、`M26-SWAP-001`、`M27-SWAP-002`、`M29-SWAP-003`、`M30-SWAP-004` | 手牌不超8；免費換牌的 CardInstance、時序、失敗原子性 |
| `PRE3-R04` | `07`／`20` | `P1-RXN-005/006` + `PRE3-RXN-JIT-001`（新案例） | Reaction Queue JIT 重驗、失效免扣費 |
| `CORE-01` | `20§7`、`21§1` | `P2-OUT-01/02/03` | 雙方 HP0 但最後敵人死 → VICTORY；否則可能 DEFEAT |
| `CORE-02` | `08§8`、`20§7`、`21§1` | `P2-LAST-01`～`06` | 施法者 HP0 撤銷 pending LastSpell；一般干擾非同一事件 |
| `CORE-03/04` | `07`、`20§7`、`21§1` | `P2-VIS-01/02`、`P2-RXN-01`～`04` | 無移動指令、無反應倒數，FPS 不影響結果 |
| `P2-D16` | `12`、`13`、`19` | `P2-REPLAY-01`、`RNG-001` | 相同 seed/command/ruleset 事件及 state hash 相同 |

此表僅是示例，Agent 必須實際**掃描 `13` 中所有當前有效 Test IDs**，為每個指定本次里程碑／Deferred / Blocked 理由。不得把未跑測試標綠，也不得把歷史測試期望（如 DRAW/死後續唱）選為 oracle。

## 5. Test-first 與確定性驗證契約

### 5.1 測試先於實作

先選需求 ID，再寫該需求的**可失敗** oracle，至少 Positive、Negative、Boundary；跨 Actor、Phase、Reaction/Delayed Effect 時再寫 Event Order；隨機性、牌堆洗牌、傷害與 ResultState 需用固定 seed Replay。若需求資料不足，將特定 case 標 `BLOCKED_FIXTURE`，不得編造 Enemy/SP/Balance 內容使其通過。

### 5.2 測試執行環境查核

```bash
# 以下只在已定位「真實 Godot 專案」且存在對應檔案／命令時執行：
"$GODOT_BIN" --version
"$GODOT_BIN" --headless --path "$GODOT_PROJECT_DIR" --script res://tests/run_all.gd
```

- `GODOT_BIN`、`GODOT_PROJECT_DIR` 必須由實際工作環境確認；不得假設 executable 一定叫 `godot`。
- `res://tests/run_all.gd` 是**待 Agent 建立並驗證的 runner，不是 Godot 原生自帶**。不支援的 CLI flag 要依該 Godot 版本修正，不能假裝命令已執行。
- Runner 結束時輸出執行／通過／失敗／跳過數、失敗 case ID、seed、初始 state hash、ruleset/content 版本、event hash、final state hash；**任何失敗應 return 非零 process exit code**。Runner 自身正反自測：引入故意失敗的 fixture 必須得到 non-zero exit，正常 fixture 得到 zero。
- 可透過 `OS.get_exit_code` 以外該版本適用的程式結束 API（例如 `get_tree().quit(exit_code)`）執行退出；以真實 Godot CLI 驗證生效。CI 再檢查 `$?`。
- 不得依賴 Tweens、AnimationPlayer、Wall Clock、GUI window、輸入裝置速度、2.5D node 來決定 Domain outcome。

### 5.3 核心屬性測試（Property-based / invariants）

必測 `HP >= 0`／資源合法下限（Overload Debt 例外由模型獨立表達）、單卡 instance 同時僅在一牌區、恰12張卡守恆、手牌≤8、已扣費事件不重扣、每玩家階段每角免費換牌≤1、每 EnemyAction per actor 已執行 Reaction≤1、已無效 delayed spell 不能發傷害、所有合法事件的 `event_seq` 單調遞增、相同 replay 事件與 hash 一致。

### 5.4 三次執行上限（防修復迴圈）

**同一測試群組**：第一次執行 → 若失敗可修正再執行第二次 → 再修正最多第三次。**第三次仍失敗就停止該里程碑**，不能再改名稱、抑制 assertion、刪測試，不能自動重設計數。報告必含 `test_case_ids`、實際命令、引擎版本、錯誤／預期、三次 attempts 的 git diff 摘要與日志、疑似根因、影響範圍及建議操作。不得因開發時間壓力跳過最後回歸 Gate。

### 5.5 分層驗收

1. **Spec acceptance**：文件明列 expected behavior，不代表有 runtime 證據。
2. **Automated acceptance**：unit / integration / event order / replay / invariant 都已實際跑過，附 log/exit。
3. **Gameplay acceptance**：實際可操作一整場，檢查告知（Intent）、可辨識卡牌、操作 Reaction、LastSpell/Exposed/Break 可理解，截圖/錄影與事件日志相互核對。
4. **Balance acceptance**：使用固定不同 seed 至少100場對照，報告完成回合、勝率、資源瓶頸、卡手率、Full Chant 中斷率、LastSpell 參與度與統計結果；provisional 數值即使跑過仍不能自動升格為永久 Canon。

## 6. 永遠不得用來宣稱 DONE 的情形

- 單純寫好 GDScript、`print("PASS")`、編譯未報錯、文件寫了驗收案例、展示假截圖；這些**不**等於完成 Gameplay/Implementation Gate。
- 只測 happy path，不測死亡、手牌上限、Reaction JIT 失效、延遲中斷、同歸於盡、同 seed 不一致。
- 不跑實機 Godot，也不提供 exit code、seed、日志；不能自創宣稱全部 PASS。
- 在 GitHub 規格 repo 編造 `project.godot`、捏造另一個私有 repo 或操縱未授權的 branch。
- 為了讓測試變綠而更改已核准的遊戲規則、弱化 assertion、將 `PROVISIONAL` 視為已經批准。

## 7. 每階段 Engineering Note 與交付模板

```markdown
# PH3-Mx Engineering Verification Note
Date / Agent / Source-spec Commit / Source-code Repo & Commit:
Godot executable & exact version / OS / command / exit code:
Requirements in scope (ID | file § | source status):
Implementation files changed (path | reason):
Tests (ID | positive/negative/boundary/replay | execution status | log path):
Determinism (seed | ruleset_version | initial_state hash | command tape | event hash | final state hash):
Design choices (why | alternatives | risk | compatibility):
Open issues (BLOCKED | PROVISIONAL | deferred to Mx):
Attempts (1/2/3) and evidence (if any failure):
Regression and CI status (actual run, never guessed):
Milestone Verdict: DONE / BLOCKED / IMPLEMENTED_NOT_VERIFIED / SPEC_ONLY
```

每次提交必附 `git diff --check` 類似靜態檢查結果（適用環境時）、對應需求 IDs、測試/日志、實際 commit 及開發分支；未通過 Gate 禁止標 DONE，亦不得自動進下一階段。**報告應讓非作者 Codex Agent 在全新對話只讀文件就能重現測試與查到與需求的關係。**

## 8. 準入與完成 Gate

- **Step 0 — ENV GATE**：實際 Godot repo、`project.godot`、引擎版本、既有測試框架、目前 commit、source-of-truth 版本、准許修改範圍已確認；缺失時停止實作並報 blocker（不是測試失敗重試）。
- **Milestone Gate**：該步 scope 每一需求有 source/實作/test/evidence 對照；所有該步 mandatory automated tests 真實 PASS；新舊回歸不倒退，必要新 fixtures 已建立；已提交當步工程 Note。
- **Implementation Gate**：Phase 3 M1～M5 全部通過各自的 Domain acceptance，不存在靜默吞掉的 critical failure。
- **Playable Gate**：具備完整內容垂直切片、可操作且中英 i18n 的 2D／2.5D HUD、玩家實際體驗驗收；此 Gate **不是** M5 完成即自動成立。

依 `23_PHASE3_EXECUTION_PLAN.md` 逐個完成。當 Agent 只接到「執行 Step 1」，**絕不能越權實作到 Step 2～5**。