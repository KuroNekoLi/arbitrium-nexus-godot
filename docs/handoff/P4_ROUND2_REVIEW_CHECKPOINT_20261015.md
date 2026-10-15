# Phase 4 Round 2 — Reviewed Integration Checkpoint
> **2026-10-15 reviewed continuation**：已依使用者新授權，將**獨立通過 Headless Gate** 的 Lv40 Domain/metrics、雙語 ReadModel、HUD Components/VFX 以三個獨立 Commit 選擇性推回 master（`c2796e31`、`d4d5b998`、`f40686cd`）。**禁止整個本分支 Merge 的原限制仍有效**；P4.4 GUI 14/16、P4.5 playable、P4.6 actual strategy/GPU/human 均仍 `NOT_VERIFIED`。新的唯一合併與未決目錄：[Master Review](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/master/docs/handoff/P4_APPROVED_MERGES_AND_PENDING_REVIEW_20261015.md)。

日期：2026-10-15。狀態：NOT VERIFIED；禁止直接合併 master。

## 版本、權限與工作區
- Repository: KuroNekoLi/arbitrium-nexus-godot；正式分支 master（不存在本次要求中的 main，未新建 main）。
- 最新 fetch 的 master：e4468a75657a7a17e030d95bb955118249f75b25。
- 工作分支：integration/p4-reviewed-20261015。
- 專用工作樹：C:/Users/user05/.codex/worktrees/p4-reviewed-integration/referenced-chatgpt-conversation-this-is-an。
- 原工作樹及使用者未提交修改均未清除。Godot 匯入會改 SimpleCards layout cache；該兩檔不納入本次提交。
- Godot 4.7.2.stable.official.ed1daf0bf，Compatibility。沒有更換 renderer、素材框架或安裝新插件。
- 使用者授權延伸既有 M5；不得另建引擎。所有 Lv40 值仍 BALANCE_PROVISIONAL。
- 使用者要求額度低於30%交接；本次30%附近預先保存，最後查核剩28%後只做保存推送，不兌換 reset credit。

## 分支整合盤點
下列均為本地整合，非 master 驗收完成：
| 分支 | 審查來源 SHA | 處理 |
|---|---|---|
| handoff/p4-lv40-chat-20261015 | 8c24c5680dac778430c682fa21865b2353222f79 | 合併；修正公開招式循環錯位；邊界 suite 仍 FAIL |
| handoff/p4-card-localization-chat-20261015 | 7274fff42df37a948188baa51f9feef27fce51bb | 合併；修正 Domain 卡名 key 對不上 CSV |
| handoff/p4-readmodel-chat-20261015 | 31d364b73832b1382f456cfb197f6dea06bbf7e4 | 合併；29 assertions PASS |
| handoff/p4-balance-research-chat-20261015 | 0efaea66ae68243127757b5175efa54b91d53a21 | 合併；修正統計驗證及 hash；修正後尚未執行 |
| handoff/p4-performance-qa-chat-20261015 | e5912d0f7778117e29182d452e6c89114c6a6e22 | 合併；修正暖機 deadline/CLI/命名；尚未執行 |
| handoff/p4-encounter-ui-chat-20261015 | 4053c2ad9c087a0a8005806afa3adc54c4cc583e | 合併 staging；修正空 snapshot 鍵盤入口；仍不是 Lv40 可玩畫面 |
| ui/hud-visual-refactor-20261015 | c45ccdc7005882894b45388b2cd46eb3bf0d4bf4 | 合併元件化；保留 P44 settings/result/reaction 相容性 |
| engineering/ci-evidence-gate-20261015 | e4468a75657a7a17e030d95bb955118249f75b25 | 已在 master |
| handoff/p4-dispatch-index-20261015 | 9423f6745dd3e076b0104c58562ffab441a33d08 | docs 派工索引，未合併；不代表 runtime 交付 |
| phase3/m5-3-boss-break-exposed-combo | 1615d3407456eaaafee47fc1a34f235e30bf0286 | 歷史分支，非 master ancestor；大量舊差異，禁止直接合併 |
| phase3/m5-4-outcome-core01 | df3e39cbea18c2ef0bc6b151fc6bdb9de4584e87 | 同上；尚須逐 patch 檢查，不能只用 ancestry 判斷等價 |
| phase3/m5-5-full-battle-replay | 2b47e42bb19f77d56af15f1bc72e0a4102f6a7bf | 同上；相對 master 刪除271檔差異不可覆蓋現行成果 |

**未完成所有 active 分支逐行審查，不得宣稱已全部 review / merge。**

## 實際測試與重跑帳本
完整原始 log 在 outputs/p4_review/evidence/；execution.json 記錄命令、版本、退出及 hash。
| 群組 | 本輪紀錄 | 結果與限制 |
|---|---|---|
| Lv40 content | core-attempt1 runner1 | 37/37 PASS |
| Lv40 domain | core-attempt1 runner2、domain_attempt2、domain_attempt3 | 81/83 FAIL → 81/83 FAIL → 83/83 PASS；已用3次，不可擅自第4次 |
| Lv40 edges | data-attempt1 runner1 | 執行至 Last Spell 失衡案例，key 不存在，45秒逾時 |
| Lv40 edges | edges-attempt2 runner1 | 37 executed、32 PASS、5 FAIL；Guard 修正因 CONCENTRATING_UNSUPPORTED_M4 不成立，已還原失敗修正；第三次尚未執行 |
| component/import | components-attempt1 | import exit0但 Parse Error；helper正確拒絕，沒有執行 runner |
| component/import | components-attempt2 | import乾淨；component24/24、localization198/198、readmodel29/29 PASS |
| balance/profile metrics | 修正後 | NOT_EXECUTED |
| Lv40 staging input | 新增2 assertions | TEST_WRITTEN / NOT_EXECUTED |
| P4.1～3 回歸、1238 Domain、100 seeds、4 Legacy | 本輪完整整合版本 | NOT_EXECUTED，不套用舊 CI 結果 |
| P44 GUI | 既有3次，第三次14/16 | 使用者明確拒絕額外重跑；本輪沒有重跑，不可改名重置 |

原 master 程式90f2ded3aa673050ba76062a96d0829cfe35d986的已記錄 CI：
https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38693953249
不是本整合分支 CI。此次 checkpoint 尚未取得新 CI。無新的 GUI screenshot、無真人試玩；REAL_PLAYER_PLAYTEST_NOT_VERIFIED。

## 重要缺陷與已完成修正
1. 公開 B05/B06 消耗與 cycle_index 脫節，釋放後又宣告無 pending cast 的 B06，導致 LV40_RELEASE_REQUIRES_DUE_CAST。lv40_boss.gd 改消耗公開循環項目；B10/B11 消耗其替代項目。不修改候選傷害。
2. Domain card.u01.name 與 LV40_U01_NAME CSV 不一致；lv40_content.gd 對齊已存在的 key，新增26筆跨契約 assertions。
3. HUD 元件化原本遺漏 reduced/mute/skip/outcome/restart；補實際控制項和 facade，不只是新增空變數。ActionContext 使用 ScrollContainer；已修正 UI.column 只接受 PanelContainer 的解析問題。
4. ReactionQueue 保留2欄捲動、特殊反應目標/tooltip、Guard/Protect/Special三類文案，避免將特殊反應誤標 Protect。
5. EnemyStatus 每次 render 清除舊 Intent。
6. Lv40 staging 空狀態關閉 _input/_unhandled_input 並保留空 snapshot guard，避免1/2/3/Space存取不存在的 core。仍 fail-closed，不冒充完成。
7. 統計 helper：統一線性百分位、來源 hash 納入 metrics、拒絕錯型/空策略/重複策略。
8. profiler：暖機及採樣共用 deadline、超時關閉 renderer measurement並釋放 scene、嚴格 CLI integer、TIME_PROCESS 更名 process_frame_ms（非純 script CPU）。新增28 assertions尚未執行。

## 待辦：交給下一位工程 Agent
先 fetch master、讀本文件與 AGENTS/主控Skill/SpecGuardian，核對 quota、dirty state、目前 source SHA。
不得在原工作樹覆寫使用者修改；繼續此分支。

### A — 關閉 review 缺口
- 檢查 scripts/domain/m5/lv40/* 全部實作與 docs/combat/25、26、27、29 正式有效內容逐項對照；主控尚未完成全部內容 parity。
- 修 tests/test_lv40_edges.gd Last Spell fixture：先查每次敵傷及HP0取消事件。已證實施法中的 B 不能 Guard，不能放寬該規則。
  建議用獨立測試 setup 提供足夠 HP Barrier（不修改原 instability assertions），確認 Barrier 不會阻止 on-hit disruption；另有HP0取消測試不得弱化。
  **先定位證據，再用剩餘第3次機會**。失敗即停，不能換檔名重跑。
- 執行 tests/test_p4_balance_metrics.gd、tests/test_p4_profile_metrics.gd；每組保留原始失敗與最多3次帳本。
- 執行 tests/test_p4_lv40_ui.gd staging；含新增 blocked keyboard assertions，不能當成可玩驗收。
- 檢查 profiler malformed CLI/暖機超時清理，外部 timeout仍必要。
- 對 historical phase3 分支逐 patch 檢查真正未整合修正；不能用整分支 merge蓋回舊程式。
- 檢查 UI components 檔尾空行（git diff --check曾報9檔），小範圍格式修正即可。

### B — CI與基礎回歸
- 修改 .github/workflows/godot-m5-5-acceptance.yml：允許 integration/p4-reviewed-20261015 驗證，新增 Lv40/content/localization/readmodel/component/metrics suites；
  先取得新suite的真實正確計數，再設 exact assertion gate，不能猜count。
- 保留完整1238 Domain、100seed replay、4 Legacy、P4.1 Scene8/P4.2 HUD36/P4.3 integration31、P44 feedback45/edges80、故意失敗probe17、assert_godot_logs總Gate。
- UI 元件化必須跑 P4.1～3既有回歸及重入/locale/reaction測試。整合分支 CI成功也不能替代未通過 GUI。
- 新 CI 要記真實run/head SHA/job/log；失敗保留，不更新預期來遮缺陷。
- 完整基礎回歸及相關gate未成功前，**不要merge/push master**。

### C — P4後續（有序，不跨Gate）
- P4.4原GUI第3次14/16且用戶拒第4次；只有用戶新明確授權才能再跑相同組。
- P4.5：修改 scripts/battle/battle_screen.gd 真正選 config/initial，將 config傳 Factory.card/Adapter.project、
  CardAppearance用Lv40實際資源、角色/Intent names用資料key、選target/mode/LastSpell support/Reaction走M5。
  不能單純刪staging gate後套fixture；保留原 default fixture供既有回歸。
- 改 tests/test_p4_lv40_ui.gd staging 的方式必須有明確需求遷移紀錄，另建真完整互動/Domain一致/Replay/場景重入測試，不能把gate期望換成true稱完工。
- 檢查 tests/capture_p4_lv40_ui.gd全文再實際截圖；現場確認1280x720、1920x1080、繁中/英文，Boss不裁切、手牌安全區及緊密斜向隊形。
- P4.5過Gate後才跑正式P4.6 4策略x100seed研究、記tape/hash/content版本/耗費/分布；不得把fixture策略勝率當平衡。
- 真人尚未測，AI/自動GUI不代表真人已通過。

## Engineering Note
### 目標與來源
本輪是 review/相容性修復，不改已批准AP/MP/RP/卡區/Outcome。依 COMBAT_IMPLEMENTATION_CONTRACT、Phase4handoff、UI02資料單向流與 Spec Guardian。
### Godot與責任
BattleScreen提交Command；M5擁有state；Adapter投影；HUD組合小型Scene；Director只播放events。
Container決定排版，ScrollContainer包VBox避免長英文/多控制項外溢；公開facade保留舊caller/test依存。
### 為何如此與替代取捨
整體替換HUD易丟失已驗證交互；保留facade使分場景逐步遷移可驗證。替代是同時修改所有caller，但增加回歸面。
### Android/Kotlin對照
BattleController≈ViewModel的action入口；Reducer≈immutable StateFlow更新；HUD≈組合UI；Signal≈callback/Flow；
ready順序類似view inflation後取binding，元件尚未ready不可取其null欄位。Render清空過期Intent類似RecyclerView bind必須重設所有可重用欄位。
### 測試與證據
元件24、翻譯198、投影29與Domain83僅證各自上述版本/範圍，不證全Battle。Parse exit0仍可有SCRIPT ERROR，必須讀loggate。
### 面試追問
為何動畫不能決定傷害？如何防重Command？如何讓Re-entry/locale重建不重複signals？為何immutable snapshot仍要Domain重驗？失敗測試與不成立fixture修復怎樣保存？
### 延伸
Godot官方文件入口已列於 architecture/UIUX/QA Skill references；先讀與此修改直接相關章節，不需新框架。

## Skill與Owner
主控：orchestrator/SpecGuardian；架構、combat、UIUX、QA用於本次真實檢查修復。
Rendering/asset skills已檢查產線需求，本checkpoint未新增美術；既有素材/授權保持原樣，不宣稱已完成新Asset QA。
Singer僅擁有6個balance/profile工具與測試檔修正；James只讀UIreview。主控擁有Domain/UI/合併/報告，統一執行Godot。



## Review continuation — 2026-10-15（GitHub 分支實際執行；不是 master / GUI 驗收）

> **Checkpoint remains NOT VERIFIED / DO NOT MERGE MASTER.** 最新受測 **程式碼** `26c29daa315340ba46db34cfb21a56a1a828fd45`；與本次交接相關之第二輪 [Actions #38715501522](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38715501522) 已 **completed/success**。最後只增加 docs 時不自動重跑 CI；須以受測 SHA 回報。分支仍是 `integration/p4-reviewed-20261015`，沒有 PR 或 master merge。

### 本次修復與可重現根因

1. **Lv40 Last Spell / Casting Stability edge** — `tests/test_lv40_edges.gd` 原情境在第三次 B03 命中前可能先使朱音 HP0，Last Spell 按 CORE-02 正確取消，導致測試無法走到預期的 destabilized-weaken 分支。測試 setup 現以 `hp_barriers={"B":4000.0}` 吸收 HP 傷害，但 B03 **命中仍會呼叫 on-hit Casting Disruption**。仍維持真實 B03 hit、5 Stability 干擾、兩次閾值與 `planned_resolve_round=4` 既有 oracle；**沒有允許 CONCENTRATING 的角色 Guard**、沒有放寬任何核准規則。
2. **Profile CLI overflow / log false green** — 失敗 [Actions #38714505252](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38714505252) 的 `test_p4_profile_metrics` 顯示 30/30 PASS，但呼叫 `int("18446744073709551621")` 產生 Godot `ERROR`；`assert_godot_logs.py` 正確阻擋。已在 `tools/qa/p4_profile_metrics.gd` 以 ASCII 十進位、去除前導零、長度/範圍預檢**先擋溢位再轉 int**；沒有隱藏錯誤或降低測試斷言。
3. **CI triggers / expiry** — Workflow 已允許此 integration 分支 Push 檢驗，也追蹤 `tools/qa/**`、`tools/balance/**`；新增 Content、Components、Localization、ReadModel、Balance Metrics、Profile Metrics、UI Staging 的 exact-count gates。Lv40 Edge 測試第三次已用盡：未來 **Push / PR 自動跳過**，僅在新獲使用者明確授權並由 maintainer 手動 `workflow_dispatch` 指定 `allow_lv40_edge_rerun=true` 時才會跑，不得藉重命名或其他分支自動繞過。
4. **UI reusability / staging** — 九個 `scripts/battle/ui/components/*.gd` 的 EOF 多餘空行已移除，原 facade、signals、控件、互動不變；`battle_screen.gd` Staging 的過時「Domain/ReadModel/Localization 未合併」警告改成真實「尚未接入 Lv40 playable Controller」訊息，仍 fail-closed，沒有解除 blocked gate。

### 真正執行過的證據（分別對應受測 Source SHA）

| Group | 數值與證據 | 定義與限制 |
|---|---|---|
| Lv40 Edge 最後第 3 次 | [Actions #38714794598](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38714794598) — **37/37 PASS、no Godot ERROR**；code SHA `8650740a076280930926b92048f98c9749d9c169` | 先前 data-attempt1 timeout；edges-attempt2 32/37 FAIL；本次是剩餘且最後一次；後續 **NOT_RERUN** |
| Lv40 Content | 37/37 PASS | 內容版本 fixture；非全面人工 parity |
| Component contract | 24/24 PASS | headless 元件契約，非完整操作 GUI |
| Localization | 198/198 PASS | 翻譯 key/字串內容測試，不是兩語畫面目視 QA |
| ReadModel | 29/29 PASS | Domain snapshot 投影契約，不是可玩完成 |
| Balance metrics pure test | 35/35 PASS | 統計 helper 正確；**4 strategies ×100 seeds 研究 NOT EXECUTED** |
| Profile metrics pure test | 30/30 PASS，logs ERROR=0 | CLI/unit test；**GPU/CPU 實測 NOT EXECUTED** |
| Lv40 UI staging | 10/10 PASS | 驗證拒絕輸入/阻擋仍成立；**Lv40 真 UI NOT IMPLEMENTED** |
| Lv40 Domain 83-case | 83/83 PASS（本 checkpoint 原始 `domain_attempt3.log`） | **先前第3次紀錄；本次雲端 CI 沒再跑第4次**。本輪沒有改動 `scripts/domain/m5/lv40/` |
| Full M1–M5.5 baseline | 1,238/1,238 (含100 seeds) | 由原 [Actions #38715501522](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38715501522) 全部前置 Domain steps Success，M5.5 100 seeds 110/110 PASS |
| Legacy smoke | 4 scripts PASS | 同一個成功的 GitHub Actions job |
| P4.1/P4.2/P4.3 | 8/8、36/36、31/31 PASS | 同一成功 job，仍屬 Headless |
| P4.4 Headless | feedback 45/45、edge 80/80 PASS | **不等於使用者已拒絕第四次的 P44 GUI Input 14/16 成功** |
| Final code ref CI | [Actions #38715501522](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38715501522) — **completed/success**, SHA `26c29daa315340ba46db34cfb21a56a1a828fd45` | Edge 第3次已在上一個成功 Run 驗證，故此 CI 明確 **skipped** Edges，不能把 skipped 當新 PASS |

兩份成功 Workflow 都可在 GitHub Actions 的 Job Log 查到原始摘要；`assert_godot_logs.py` 對非故意失敗 probe 的錯誤採嚴格拒絕。首個失敗 workflow 的 Godot 64-bit 溢位日誌保留為修復證據。

### Lv40 內容 Source-of-Truth 對照範圍（部分已核對，非全面）

- `lv40_encounter.gd` 三張各 12 SP 牌組與 `docs/combat/26` 的 `REN/AKANE/TSUMUGI_STARTER_V0_3` 完整清單一致。
- `lv40_content.gd` 的 `Boss HP=2700`、`Break max=22`、`PAtk=417`、`MAtk=434` 是 `docs/combat/29` 的 **候選 A**，而不是 `docs/combat/27` 歷史 Boss HP3000 / Break30。仍屬 BALANCE_PROVISIONAL。
- `U01–U05` 的 starter 權限及部分成本／魔法傷害係數與 `26` 一致；`B03` on-hit Casting Disruption 由新的 Edges 真正測試。
- **未完成**全部 `scripts/domain/m5/lv40/*` 每一技能/狀態/例外分支與 `25/26/27/29` 的逐規則審核；不能升級成 `CONTENT_PARITY_VERIFIED`。歷史 Phase3 分支仍未逐 patch 審查；禁止直接合併覆寫。

### 必須保留的阻擋與下一階段 Owner Gate

- **P4.4 GUI**：第三次 14/16，使用者明確拒絕第四次；本次完全**沒有**實際重跑 GUI Input suite。要跑第四次必須先得到使用者新且明確的授權。
- **P4.5 Lv40 UI**：Staging 10/10 只證明 `BattleScreen` 阻擋啟動、鍵盤不會破壞空 Snapshot；尚未建立真正 Lv40 ContentConfig → Factory/Adapter → Controller → 選目標/模式/Last Spell/Reaction → 完整 playable Boss Battle 的人工／自動化 Gate。保留原有 fixture 與負例，不得直接把 staging gate 換成 true。
- **P4.6**：四策略 × 100 Seed 正式 Lv40 Godot 研究、GPU/CPU GUI profiling、真人 playtest／平衡決策 **NOT EXECUTED**。
- **Git**：本輪只在 `integration/p4-reviewed-20261015` 推進並保存；未合併 master。使用者原工作樹、兩個 SimpleCards cache 與未提交資產不應被破壞；GitHub API 操作不會讀寫使用者本地工作目錄。

**狀態總結：Branch Headless Review QA PASS（明列 scope），P4.4 GUI NOT VERIFIED、P4.5 Playable NOT VERIFIED、P4.6 NOT VERIFIED、Full Round2 Review / MASTER MERGE BLOCKED。**
