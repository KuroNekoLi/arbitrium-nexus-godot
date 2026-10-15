# Remote branch 語意稽核（2026-10-15）

## 結論與適用範圍

固定比較基準為 `origin/master`／HEAD `5349950e929546515f0669ae433beaf3c4281d63`。本輪完整枚舉 **17 個 remote refs（16 個非 master 分支）**，逐 ref 執行 merge-base、左右歷史計數、未納入歷史、git cherry、差異路徑與 blob 對照，再閱讀關鍵功能差異。**目前沒有辨識出需要從這些 refs 再採用的獨有、仍有效 production 功能；不建議 full merge 任一分支。** 這是限定於已查核內容的結論，不是所有歷史程式逐行正確性的保證。

主分類：**A already 7、B superseded 9、C ready 0、D fix 0、E blocked 1**。A 包含非祖先但 production blob 已相同的情況；B 表示原功能已由現行版本承接或修正，並不要求保留原 commit 拓樸。E 指 reviewed 分支殘留的測試／驗證工具與執行限制，不代表還缺其 production 實作。

Lv40 positive UI 由主控另行實作，本稽核不重做、不評定其未提交成果。原 GUI、Lv40 domain83、edges37 均已三次且禁止重跑；本輪 **沒有啟動 Godot、測試、GUI、CI，也沒有 fetch、merge、cherry-pick、commit 或 push**。唯一寫入 owner 是本報告，使用 apply_patch。

## 來源、權限與方法

| 項目 | 本輪採用內容／限制 |
|---|---|
| 工作區 | `C:/Users/user05/.codex/worktrees/p4-final-integration/referenced-chatgpt-conversation-this-is-an` |
| Remote | `origin = https://github.com/KuroNekoLi/arbitrium-nexus-godot.git`；使用已 fetch refs，不宣稱是查詢當下 server 的最新狀態 |
| 規範 | 已讀根 AGENTS.md；檔案搜尋只找到此 repo 根 AGENTS.md，檢查相鄰上層未取得額外 AGENTS.md |
| 技能 | 已讀 orchestrator、其 Spec Guardian、architecture、其 Spec Guardian、GAME_ARCHITECTURE、GDSCRIPT_STANDARDS |
| 規格效力 | 00 索引、21 CORE-01～04、22 工程契約及23計畫相關內容；最新 USER_APPROVED > 有效 APPROVED > DELEGATED_DEFAULT > BALANCE_PROVISIONAL > 歷史。未重新逐條驗收全部 00～31 |
| 實際專案 | `project.godot`：main=`res://scenes/battle/battle_screen.tscn`，feature `4.7`、1280×720、gl_compatibility、CG autoload；不能據此推定本機 patch 版本 |
| 版本證據 | CI workflow 指定 Godot 4.7.2；歷史 `CI_EVIDENCE_GATE_ENGINEERING_NOTE.md:23` 記載 `4.7.2.stable.official.ed1daf0bf`。本輪 PATH 查詢未找到 Godot command，也未啟動 binary；不是本輪版本／runtime 驗證 |
| 既有測試 | 盤點 M1～M5、Phase4、Lv40 測試及 workflows；讀取歷史 promotion receipts，不把舊 PASS 宣稱為本輪重測 |
| 盤點腳本 | 呼叫 orchestrator `scan_project.py` 的唯讀掃描，但 PowerShell ConvertFrom-Json 遇編碼／escape 錯誤，未取得可用解析結果；未修腳本。核心判斷另由直接 Git／檔案讀取建立 |
| 並行保護 | 開始時乾淨；後續 status 出現 controller、screen、UI、capture runner、playable scene/test、UID／translation 等並行改動。HEAD 仍為固定 SHA。本報告對照 **commit blobs**，不將這些 dirty／untracked 檔案混入結論，也不清理或覆寫 |

所有 refs 都做 `git merge-base BASE REF`、`git rev-list --left-right --count BASE...REF`、`git log BASE..REF`、`git cherry BASE REF`。以 `BASE...REF` 找分支真正引入的差異，再以 `git ls-tree -r`／`git rev-parse REF:path` 和 `git diff REF BASE -- paths` 檢查現行替代版本。P4 worker 額外以共同 checkpoint `1cc34f6e483c6b871ffa9d1f5023f26b7950fd3d` 區分共用 WIP 與個別任務；HUD 分支則以其 merge-base 為起點。

`git cherry` 是 patch 等價檢查，不能識別 squash、多 commit 重組、按檔案 promotion 或修正版的語意等價；`+` 不能直接列為待合併功能。歷史分支沒有後來新增的 UI／Lv40 檔案，也不表示該分支提出刪檔需求。

## 全部 refs：分類、full SHA、歷史與 scope

以下 ref 名均帶 `origin/`，其完整命名為 `refs/remotes/origin/...`。左右數為「僅 BASE／僅 REF 可達 commits」；cherry 欄為 `+ / -`，與左右歷史不同（merge commits 不逐項列為 patch）。MB 代號完整 SHA 見下一表。

| Ref | full SHA | MB | 左／右 | cherry +／- | 分類 | 差異 scope／證據與處置 |
|---|---|---|---|---|---|---|
| `origin/master` | `5349950e929546515f0669ae433beaf3c4281d63` | M0 | 0／0 | 0／0 | A already | 固定比較基準；沒有待採用差異 |
| `origin/engineering/ci-evidence-gate-20261015` | `e4468a75657a7a17e030d95bb955118249f75b25` | M1 | 4／0 | 0／0 | A already | 真正祖先，90f2ded CI log gate／legacy audio test 修正已進基準；不再 cherry-pick |
| `origin/integration/p4-approved-headless-slice-20261015` | `c2796e312317baaf4bdcebbb6295927b00ff364a` | M2 | 3／0 | 0／0 | A already | 真正祖先；Lv40 八 adapter、七 bridge、content、pure balance/profile helpers 已 promotion |
| `origin/integration/p4-approved-presentation-contracts-20261015` | `d4d5b9986fc4d8d51227566dccc7573ddbae87df` | M3 | 2／0 | 0／0 | A already | 真正祖先；雙語 catalog、26 appearances、factory/readmodel 已 promotion |
| `origin/integration/p4-approved-hud-headless-20261015` | `f40686cda795aa61035f7473b08c8730409655b6` | M4 | 1／0 | 0／0 | A already | 真正祖先；HUD component、VFX、fail-closed scene 已 promotion；不等於 GUI／playable 通過 |
| `origin/handoff/p4-card-localization-chat-20261015` | `7274fff42df37a948188baa51f9feef27fce51bb` | M5 | 6／8 | 8／0 | A already | 任務新加 catalog 與 atomic translation loader blob 與 BASE 相同（E2）；共用 checkpoint 其餘舊內容已由新版承接 |
| `origin/handoff/p4-readmodel-chat-20261015` | `31d364b73832b1382f456cfb197f6dea06bbf7e4` | M5 | 6／8 | 8／0 | A already | factory 與 adapter blob 均相同（E3）；不是缺少八個 production 功能 |
| `origin/handoff/p4-lv40-chat-20261015` | `8c24c5680dac778430c682fa21865b2353222f79` | M5 | 6／16 | 16／0 | B superseded | M3/M4/M5 wiring 已相同；Boss cycle 與 content i18n key 有現行修正（E4）。portable patch 為歷史材料，不套回 |
| `origin/handoff/p4-balance-research-chat-20261015` | `0efaea66ae68243127757b5175efa54b91d53a21` | M5 | 6／8 | 8／0 | B superseded | policy＋metrics 已 promotion，現行補 quantile、paired validation、source hashes（E5）；400 場研究仍未驗證 |
| `origin/handoff/p4-performance-qa-chat-20261015` | `e5912d0f7778117e29182d452e6c89114c6a6e22` | M5 | 6／9 | 9／0 | B superseded | profiler harness 已承接；helper 新增 conversion 前範圍檢查，避免超大整數造成 Godot ERROR（E6）；沒有實測 GPU 結論 |
| `origin/handoff/p4-encounter-ui-chat-20261015` | `4053c2ad9c087a0a8005806afa3adc54c4cc583e` | M5 | 6／9 | 9／0 | B superseded | inherited Lv40 staging scene blob 相同；screen 新版明確停輸入／空 snapshot guard（E7）。capture 尚受阻，不是此分支可直接補 positive UI |
| `origin/ui/hud-visual-refactor-20261015` | `c45ccdc7005882894b45388b2cd46eb3bf0d4bf4` | M5 | 6／5 | 5／0 | B superseded | 八 component scenes 相同；facade／九 component scripts 有新版補回控制與可捲動 Reaction（E8）。採用舊副本會回退功能 |
| `origin/handoff/p4-dispatch-index-20261015` | `9423f6745dd3e076b0104c58562ffab441a33d08` | M5 | 6／3 | 3／0 | B superseded | checkpoint 後僅交接／派工文件；獨有 dispatch index 無 production 行為，不需要 full merge |
| `origin/phase3/m5-3-boss-break-exposed-combo` | `1615d3407456eaaafee47fc1a34f235e30bf0286` | M6 | 55／12 | 12／0 | B superseded | 6 個引入之 code/test/CI paths：4 相同、2 已由 Outcome／Lv40 擴充；無缺檔（E9） |
| `origin/phase3/m5-4-outcome-core01` | `df3e39cbea18c2ef0bc6b151fc6bdb9de4584e87` | M7 | 52／16 | 16／0 | B superseded | 9 個引入 paths：6 相同、3 僅有後續 Lv40 opt-in routing 差異；無缺檔（E10） |
| `origin/phase3/m5-5-full-battle-replay` | `2b47e42bb19f77d56af15f1bc72e0a4102f6a7bf` | M8 | 33／16 | 16／0 | B superseded | 6 個引入 paths：5 相同，唯一差異為較舊 acceptance workflow；無 production script 增量（E11） |
| `origin/integration/p4-reviewed-20261015` | `2cdcd01d65f59e21f2d50490176dd0f11dc9209a` | M1 | 4／71 | 63／0 | E blocked（殘項） | runtime scripts/scenes/assets/addons/tools 與 BASE 已相同；剩舊 workflow、capture runner／balance tests、歷史 patch／logs（E1、E12）。不可把驗證殘項當未合併 production |

| MB 代號 | full merge-base SHA |
|---|---|
| M0 | `5349950e929546515f0669ae433beaf3c4281d63` |
| M1 | `e4468a75657a7a17e030d95bb955118249f75b25` |
| M2 | `c2796e312317baaf4bdcebbb6295927b00ff364a` |
| M3 | `d4d5b9986fc4d8d51227566dccc7573ddbae87df` |
| M4 | `f40686cda795aa61035f7473b08c8730409655b6` |
| M5 | `5103e40a4b95da82f2561b29c2604e9514fd398b` |
| M6 | `81f04531af7cad2b387d04b8646e204054bbabcf` |
| M7 | `77dc6868f902a2e86fa24c7ea2b9e88052f618a5` |
| M8 | `9b45bbf004221ff5dab9b87736a684c09e2747e8` |

分類定義：A=歷史已納入或任務功能完全相同；B=同功能已有有效替代版本／舊計畫失效；C=確認有效且可直接採用的 production patch；D=有效新功能但需先修正的 patch；E=證據、契約或權限阻擋，不能宣稱 ready。此處 C、D 為零，並不表示沒有待開發功能。

## 功能證據與歷史鏈

### E1 — promotion 不是整分支 merge

BASE 歷史依序為 e4468a75 → c2796e31 → d4d5b998 → f40686cd → 5349950e；三個 promotion 分支各自是 BASE 真正祖先。讀取 [promotion summary](P4_APPROVED_MERGES_AND_PENDING_REVIEW_20261015.md)、[headless note](../verification/PH4_REVIEWED_HEADLESS_PROMOTION_20261015.md)、[presentation note](../verification/PH4_REVIEWED_PRESENTATION_CONTRACTS_20261015.md)、[HUD note](../verification/PH4_REVIEWED_HUD_HEADLESS_20261015.md)，再獨立比對 Git blobs。

`git diff BASE reviewed -- scripts scenes assets addons tools` 未列差異；resources 唯一額外項為歷史 `pending_integration.patch`。reviewed 從 MB 引入的 code/test/CI/resource 等 98 路徑中，88 相同、2 改變、8 在 BASE 不存在。兩個改變是 workflow 與 GUI capture runner；八個缺項為 patch、三個測試／capture scripts、四個歷史 logs，詳 E12。統計不包含全部文件與 outputs，不能讀成整個 repo 僅 98 檔。

### E2／E3 — 非祖先也可以已完整承接

| 檔案 | worker 與 BASE 相同的 full blob SHA |
|---|---|
| `resources/ui/lv40_strings.csv` | `ec472a058dd5eca19bfcb25db7b6508b834145b7` |
| `scripts/battle/presentation/battle_translations.gd` | `7724b1afd49cf371ac185e73a19a63aeaf36ff89` |
| `scripts/battle/battle_command_factory.gd` | `3338fa5b84dc41bcf1bd7e8c4239c29f863c039a` |
| `scripts/battle/presentation/battle_presentation_adapter.gd` | `cdde1358218e4a3fd7d68aa4a59b60414656d79e` |

localization 任務歷史包含 `efa879cc8e62e1b2031c98e71f48d65533c1e9ef`（atomic catalog loader）、`0b67c151d21dfc93ebdfbe8fe2110ce6b0ebe6f2`（Lv40 labels）；readmodel 包含 `ca5c7493771b2e9752a64535b29a7098e606fdb7`（factory）、`af0f895ba0a344d043529f94f717059f4454cc7a`（projection）。這些功能對應 promotion d4d5b998 的內容，不能因 cherry 全為 `+` 再套一次。

### E4 — Lv40 wiring 已納入，舊 Boss／key 由修正版取代

worker 引入的 phase_engine、reaction_eligibility、reaction_queue_resolver、casting_timeline_resolver、damage_pipeline_resolver、m5_domain_resolver、lv40_domain_extension、status_resolver 八個任務 wiring paths，均與 BASE 相同。共同 checkpoint 中八個 Lv40 adapters 亦已由 reviewed/promotion 承接。

實讀 `git diff worker BASE -- scripts/domain/m5/lv40` 僅兩個不同檔案：

- `lv40_boss.gd`：worker blob `d411a2c…` → BASE `f9214cb…`。現行以 published intent 的 `replaced_skill_id`／pending release 決定 consumed cycle item，再設定 cycle_index；避免 cooldown／Break fallback 後重複 charge release。不能用舊的無條件 index+1 覆蓋。
- `lv40_content.gd`：worker `d2f0146…` → BASE `ee52a81…`。name/description key 由 `card.u01.name` 型式改成 catalog 真正存在的 `LV40_U01_NAME`／`_DESC`。這是同功能修正，不是應把舊 key 再合併。

worker 結尾 `8c24c568` 僅交付 portable unified diff；`pending_integration.patch` 不在 runtime preload 路徑，不能當額外 engine。

### E5／E6 — balance／profiler 已有新版

| 工具 | worker blob → BASE blob | 已閱讀的現行修正 |
|---|---|---|
| `tools/balance/lv40_godot_policy.gd` | `80e0571746d8d3ae93b47ee9644e0493cfa203ed` → `7f25f4cb786e1f063f54e5ab5e76eabf820eb44c` | 納入 policy／metrics 的 research_tool_hashes，執行前後檢查來源；percentile 轉給 quantile，拒絕非數字／NaN／Inf |
| `tools/balance/lv40_research/metrics.gd` | `f00a9aaa801d6a1a73f824b86ca84c95f4d31102` → `94067fb87752714679c3f11198d9132e6e082897` | quantile 拒絕不合法 probability；paired 拒絕空／重複 strategy，未成對 observation 也驗證 report/outcome |
| `tools/qa/p4_profile_metrics.gd` | `91bce3e90ead8a71e8d70775e4a6a4f2f5601c6f` → `2724a3a20246b2ab67f2df0593a32cf6f590c7f9` | `parse_frame_count` 在 int conversion 前檢查十進位字串、位數、範圍，避免 overflow engine ERROR |

reviewed 的 `00d8d790efd64ba6c3883aa8ff7674c6317064f1` 明確記錄 profiler overflow 修正；其 production tools 全部已相同於 BASE。pure metrics 35／profile30 是歷史 scoped verification，不能等同 4 strategies×100 seeds、實測 GPU 或正式平衡。無需把較舊 worker 工具列 D 待修再匯入，因同修正已存在。

### E7／E8 — staging／HUD 已有修正版，positive UI 是另項工作

Lv40 scene `scenes/battle/lv40_battle.tscn` 在 worker 與 BASE 的 blob 都是 `729c6037562ba4c973d9d830ecd2d8acd9fff9c2`。screen worker `c63b245…` → BASE `72caf65…` 的差異增加 `set_process_input(false)`、`set_process_unhandled_input(false)`、`snapshot.is_empty()` guard，並把 blocker 訊息改成正確的 playable wiring 未完成。這些是原 staging 的安全修正。

HUD 原 branch 19 個引入 paths：八個 scenes 完全相同；facade、九個 component scripts 與既有 input bindings 的11個差異 paths 均存在。實讀重點差異：結果面板／restart、reduced motion／mute／skip controls 回到 facade；action context 改可捲動；Reaction choices 改 grid／scroll，補特殊反應文字、target、tooltip，保留 Confirm／Pass／reorder 意圖。其餘 component 有 normalization 與 `_ready` 建構細節差異；未逐行論證全部視覺效果。

reviewed 歷史 `31ff08f7b6eb3965039e4f7dff9f99c6a505db78`（保留 presentation controls）、`26c29daa315340ba46db34cfb21a56a1a828fd45`（component normalization／staging blocker）及 f40686cd promotion，支持「新版已取代」結論。10/10 staging 驗證的是禁用狀態；不得把舊分支合併當 positive UI 完成。主控並行 dirty 工作不在此固定快照的評定內。

### E9 — Phase3 M5.3：按真正引入行為追歷史

master 已有 `ef3fc98d1fd2ef5f9e65974e1d2e1d3d9c34481c`（M5.3 domain）及後續 M5.4／Lv40。branch 的 production commits 為 Boss policy `f6e892a02051a215245d602bb82ae137f00439b5`、paid tactical SP `08296b302d57d9ba006a3012d693b51501e6fa7f`、integration `4bf71b203be0d394cbc06d055693e2ffab9be251`；其後多為 fixture/test/CI／證據文件。

從真實 MB 到 branch 的6個 code/test/CI paths，Boss policy、M5.3 workflow、fixture、boss_combo test 四個 blob 與 BASE 相同。Boss policy full blob 為 `bfc76af577dc116bbff33b94421245d19a4e3348`。

剩兩檔實讀差異：tactical resolver `e80a8f58b544ad0f3f483c1cb9803403dba24bf1` → `416387137a0b54aa6e71e1e3c20db45b45a79113` 增加 trusted recoil 前置驗證及整張 action 結算後 Outcome 支援；integration `37e833fdf41aecaa77cb662f81a93c4fa6d56b0c` → `0a500a7ff767c403aa56f0e4b62d1641353c8d1c` 增加 config-aware boundary、terminal rejection、拒絕偽造 recoil/outcome payload、Lv40 opt-in route。這是保留 M5.3 並依 CORE-01 擴充，沒有發現被遺漏的 Boss／Break／Exposed／Combo production patch。

### E10 — Phase3 M5.4：CORE-01／02 已承接

master 已有 `679252d61d56ecea71053692c62532a82846a94d`。branch 主要功能為 recoil HP bridge、paid-SP recoil、Last release 後 signed HP effects、action boundary 與 terminal atomicity；對照 commit history 與真正引入的9 paths，6相同、3不同、0缺檔。

完全相同的關鍵 blobs：

- `phase_boundary_resolver.gd`：`9229532cce1885edc48c87fd58823edd31344d16`。
- `hp_lifecycle_bridge.gd`：`d7965956128a0f2aef03aad53681153804d99e51`。
- `tactical_sp_resolver.gd`：`416387137a0b54aa6e71e1e3c20db45b45a79113`。
- M5.4 workflow、fixture、outcome test 亦相同。

全部三個不同 production 檔案已閱讀 diff：phase_engine 僅新增 Lv40Boss preload／lv40 counter context／opt-in enemy resolution；casting timeline 僅新增 Lv40Cast preload 及 opt-in settle；m5 integration 僅新增 Lv40 extension preload／route。舊 Outcome／Last Spell 路徑保留，沒有憑 tree 缺少 UI 就推論需要 full merge。

### E11 — Phase3 M5.5：主要是已採用的測試／fixture

master 有 `9c8b14b873047ca181a229cfaab5d2351541ceab`。branch 在 MB 後引入 full-battle fixture／driver、integration／replay／100-seed tests 與 acceptance workflow，沒有獨有 production script。五個 tests/fixtures blobs 全與 BASE 相同。唯一不同 workflow blob：branch `f4eb8fc4165afa814be7277b2c8b658fdf7181df` → BASE `6370056b5e563d7c5798ca66f5aa11e976f4a6b8`。

已讀 workflow 全部差異：現行擴大 path triggers，新增 log-gate 自測、import log gate、exit17 probe、P4 Scene/HUD/integration 與結尾 reject Godot errors；保留原 M5.5／predecessor gates。branch 的16個未納入歷史 commit 不是16個遺漏 production 功能。不可用舊 workflow 回退現行錯誤偵測。

## E12 — 真正尚未採用的殘項及處置

| reviewed 中的差異 | 類別 | 語意與具體處置 |
|---|---|---|
| `tests/test_p4_input_capture.gd` | E blocked／測試 harness | blob `829756c3b76911c4b4e0bcbb02246eda7d4528ff`，BASE `de2dff2e3b1738f2f3ef391ea41591cef83909e4`；差異為 capture-prefix、keycode、Reaction 未開時提前失敗。可有價值，但不是 production 功能，沒有本輪採用或執行授權；原 GUI 三次禁重跑仍有效 |
| `tests/test_lv40_balance.gd` | E blocked／研究驗證 | blob `4f377cb43fc3e995dd839b6ca56343b48edbb1d8`；已讀全文。無旗標時明示 `NOT_EXECUTED_WAITING_MAIN_API_READY`；`--lv40-api-ready` 才啟動 matrix／400 records、replay、output assertions。現有 pure metrics 無法替代此驗證；沒有新增 production engine |
| `tests/capture_p4_lv40_ui.gd` | E blocked／capture | blob `4a719b9ef8c73a5736b7b284710012c560f7472b`；已讀全文。要求 GUI、unique run-id、live snapshot/controller/Lv40 config；staging scene 下會 fail-closed。主控的新 positive UI scope 不由本報告重做 |
| `tests/capture_p4_feedback.gd` | E blocked／capture | blob `b560d46ffe7948a4dc50dac0f11551b90bd996de`；已讀全文。直接發送 scene commands／等待動畫／呈現 fixture final state並截圖，不能當實際玩家完整操作證據；尚無本輪圖像驗證 |
| `.github/workflows/godot-m5-5-acceptance.yml` | B superseded／CI 組態，附 E 權限限制 | reviewed blob `cce18978ff3c2585b3e048ff5daa10555a18a5e8`。含 branch trigger、額外 P4 gates，以及手動 `allow_lv40_edge_rerun`。現行三個 scoped workflows 已承接主要 headless gates；舊註解仍稱 final attempt，不能用 input 開關自行獲得第四次授權。不整檔套入 |
| `resources/combat/lv40/pending_integration.patch` | B superseded／歷史 patch | blob `f01e6c8f9a4b37477cd54b0325c2ac5c55254296`；對應 Lv40 wiring 已承接；保留 branch 可追溯，不作 runtime 載入或重新套用 |
| 四個 `tests/*attempt1.log`、`outputs/*` 與 handoff docs | 歷史證據／文件 | 非 production；未逐檔重驗 log／圖片。來源 branch 保留即可，不能把其存在當當前快照 PASS |

上表 runner 差異若未來要採用，應另外限定文件／測試 ownership 並依適用權限處理；本報告沒有建議重跑，也沒有把「可閱讀的 patch」升格成 C ready。

## 不確定處與證據邊界

1. **未逐行全看**：已逐 ref 查 history/cherry/merge-base，完整列出 Phase3 真正引入 code/test/CI paths 與不相同 production diffs；P4 重點讀取 package 增量、新版修正及 reviewed 剩餘 runner／workflow。未逐行閱讀每個既有相同 blob、全部 addons/assets、所有 docs、歷史 logs 或 PNG。部分大批工具輸出被截斷，關鍵 Phase3／package／殘項另以窄範圍查詢補讀；不宣稱截斷部分已逐行審查。
2. **相同 blob 是內容等價，不是 runtime 正確性**：它支持「沒有少採該檔」，不能證明 UI 可操作、所有 spec parity 或平衡成立。B 修正版判斷來自實際 diff 與有效規格方向，不是日期／檔名排序。
3. **CI 本輪未連線查驗**：promotion 文件記載 stage runs `38717257405`／`38718051812`／`38718716573`、reviewed `38715501522`、edges第三次 `38714794598`。這些是 repo 既有 receipts，不是本輪新取得的 Actions 狀態；尤其 stage3 master M5.5 `38718980475` 的最終狀態本報告未確認。
4. **固定 SHA 與並行工作分開**：HEAD audit 仍固定 5349950；主控 dirty positive UI、截圖 writer、新測試或引擎產物，不在本輪 remote semantic audit 的 completion 結論中。不得用本報告否定或重做其進行中工作。
5. **規格限制維持**：Domain 擁有 HP/AP/MP/RP、牌區、時序與 RNG；CORE-01 victory-first、CORE-02 釋放前 HP0 Last Spell 失效、CORE-03 無自由走位、CORE-04 無強制 Reaction 倒數。研究數值保持 BALANCE_PROVISIONAL；未發現新規則授權，也未提出改規則。

交付狀態：**REMOTE_REF_STATIC_SEMANTIC_AUDIT_COMPLETE（上述限制內）／NO_FULL_MERGE_RECOMMENDED／NO_RUNTIME_VERIFICATION_EXECUTED**。原始分支與歷史證據維持原狀；本輪不刪分支、不作新功能實作、不動主控檔案。
