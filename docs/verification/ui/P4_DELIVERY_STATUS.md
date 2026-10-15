# Phase 4 本輪交接

## G0

已pull指定repo master，起點 `7163aeff0de1f93b2c1a05e20bf7a3c3899333b7`。AGENTS、現行Combat／UI、Skills及Guardian已核對。詳見 P4_G0_AUDIT.md。沒有使用歷史Flutter／Astraea-Academy。

## P4.1 — VERIFIED

Commit `66a8b3faf776ca2d4f8371718e89ea3c89aef4fe`。

正式CI https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38681239677 completed/success。

三角／Boss slots、腳底anchor、動畫atlas、設計畫布與Adapter；Scene8/8，1238 Domain／100 seeds／4Legacy PASS。實際1280／1920截圖與Sprite3D小比較在outputs/p4_1_*。檔案與教學見 P4_1_ENGINEERING_NOTE.md。

## P4.2 — VERIFIED

Commit `961c05061665be1c518d041ce05508c225fdb8ae`。

正式CI https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38682762145 completed/success；Legacy failure-probe CI https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38682762150 completed/success。

獨立真手牌、選角、hover／拖曳、合法性dry-run、AP/MP/HP／Boss Intent、兩語、明確Reaction UI。HUD36/36，Scene8/8，1238／100 seeds／4Legacy PASS。輸出outputs/p4_2_*；重要檔案 scripts/battle/ui、resources/ui、battle_command_factory.gd、battle_translations.gd、hero_roster_item.gd。教學見 P4_2_ENGINEERING_NOTE.md。

## P4.3 — VERIFIED（續作驗收）

Commit `5103e40a4b95da82f2561b29c2604e9514fd398b`，已 push master。正式 CI https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38685051780 completed/success。先前第三輪失敗保留為歷史證據；使用者明確續作後，同名 runner 本輪 31/31 通過，沒有減少 assertion。

工作樹已接 BattleController→M5→Adapter→HUD/Director，主場景切換到 scenes/battle/battle_screen.tscn；真交易與事件演出、手動Reaction後Boss自動續行、typed CommandTape、save/replay、沿用SimpleCards扇形／Tween。沒有修改scripts/domain。

本機：Scene8/8、HUD36/36、GUI輸入16/16、完整Domain1238／100 seeds／4Legacy PASS。P4.3 原週期三次27/27、27/27、30/31；續作週期修正順序 oracle 後31/31。詳見 P4_3_ENGINEERING_NOTE.md 與 p43_resume logs。

截圖：outputs/p4_3_hit_1280.png 是Boss259/290、AP5、A MP9且角色前衝；reaction顯示DRAFTING等待；eight兩尺寸顯示真正旋轉邊界。截圖與GUI PASS不抵銷未過的順序Gate。操作者是Godot測試輸入，不是人工playtest。

## Skills / Assets

主控與Spec Guardian；Architecture負責owner／signals／tape，Combat檢查M5 API／scheduler，UIUX負責真手牌／i18n／互動，Rendering負責compact diagonal／事件演出，Resource Manager＋Pipeline盤點重用／字型／授權，QA負責runner／CI／原始證據及三次上限。P4.1～3 為單Agent依序執行；P4.4～6 本輪另啟 Domain、QA 與平衡研究子 Agent，寫入範圍見 P4_TASK_CONTRACT.md。

Kenney frame CC0、既有SimpleCards2.13 MIT，完整notice已補回；NotoSansTC OFL1.1，Vault／manifest記錄。角色／Boss／背景既有PNG是來源待清權placeholder。CGF查核main SHA、API／授權／互動，未匯入其原始碼，未替換M5。研究見 P4_RESOURCE_SELECTION.md；各素材專案路徑在assets/asset_manifest.csv。

## Git／限制

遠端master已到P4.3 SHA。P4.4 呈現改動與 P4.5 Lv40 新模組保留在工作樹，不能標成clean。原有 .codex/COMBAT_SPEC_MEMORY.md 保留未提交；另有本機Godot產生.uid／CSV .translation及未提交本輪證據，不把它們混入無關commit。不reset、不force push。

## P4.4 — NOT VERIFIED / QA_EXECUTION_LIMIT

事件映射45/45、獨立邊界80/80，以及1238 Domain／100 seeds／4Legacy回歸通過。真視窗取得詠唱、援護、Last Spell、勝利與雙語截圖。GUI輸入第三輪14/16，失敗項為兩張PNG寫入，不能稱整組通過。已提出「隔離輸出後額外重跑一次」問題；未取得明確批准前不第四次執行，也不提交為 VERIFIED。詳見 P4_4_ENGINEERING_NOTE.md。

## P4.5～6 — IMPLEMENTED_NOT_VERIFIED / 施工中

使用者已明確批准「授權擴充既有 M5」，範圍為已文件化的 Lv40 內容，不授權建立第二引擎或升格 Provisional 平衡。Lv40 新模組內容測試32/32通過；正式 M5/M3/M4 入口仍未接線，因此不是可玩 Boss 驗收。Domain 子 Agent 因使用額度限制中止，現有檔案已保留，由主 Agent 接手審查。平衡工具僅解析檢查，尚未執行400場研究或真人遊玩。

下一個必要 Gate 是 P4.4 額外 GUI 重跑授權／驗收，再獨立 commit、push、CI，才進入 P4.5 正式整合。沒有商售美術、完整Boss遊玩、正式balance或export完成主張。

## P4 Round 2 Reviewed Integration (supplementary evidence, NOT Phase 4 playable gate)

- Checked branch `integration/p4-reviewed-20261015`, source SHA `26c29daa315340ba46db34cfb21a56a1a828fd45` [Actions #38715501522](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38715501522): **completed/success**, M1–M5.5 1238 tests, 100 seeds, 4 Legacy, P4.1=8, P4.2=36, P4.3=31, P4.4 headless=45+80 and new Lv40/content, component, l10n, readmodel, metrics, staging suites all passed.
- One prior CI [#38714505252](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38714505252) caught a Profile `int()` overflow Godot ERROR even though 30/30 asserted PASS. Corrected; the exact unmodified 30-case suite then passed with clean error log.
- Lv40 Edges third and final allowed test: **37/37** in [Actions #38714794598](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38714794598); newer CI **skips** it to respect exhausted test budget. Lv40 Domain 83/83 from old local attempt3 is **not** rerun.
- **NOT VERIFIED:** P4.4 original real-GUI input 14/16 (owner refused fourth attempt), real playable Lv40 UI (staging 10/10 asserts it is blocked), P4.6 4×100 strategy gameplay research, real GPU profiling, real player playtesting and human balance approval.
- Details and remaining Owner Gates in [Round2 Review Checkpoint](../../handoff/P4_ROUND2_REVIEW_CHECKPOINT_20261015.md). **No master merge or playable claim.**
