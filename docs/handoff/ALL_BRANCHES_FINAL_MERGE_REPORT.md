# All Branches Final Merge Report
日期：2026-10-15。暫定狀態：BRANCH INTEGRATION PARTIAL — BLOCKED ITEMS DOCUMENTED。
隔離分支兩組CI及正式Master三組CI均成功；已fast-forward推送master。GUI及真人Gate不提前宣告成功。

## Branch Inventory
盤點基準 master：5349950e929546515f0669ae433beaf3c4281d63；fetch --all --prune 實際完成。
以下是固定盤點的17 refs；完整方法、MB代號、blob/patch語意證據見 [semantic audit](BRANCH_SEMANTIC_AUDIT_20261015.md)。
其中 A7（含master）／B9／E1。不是依序merge，不使用 merge -s ours，不刪分支。
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


新增 integration/p4-final-playable-20261015：f16227c1e67457de53b3547a73462416c32349ef。
此分支從最新master建立，只新增本次G3/G4有效技術修復及正向接線；staged兩組CI成功後已於本輪提升master，分類A ALREADY_INTEGRATED；正式Master CI待核對。
reviewed分支中的capture儲存需求已由安全writer重新實作，不套回舊workflow/keycode/GUI輸入流程；
未採用的研究／capture harness與歷史logs見Unmerged。

## Merge History
既有三批promotion並非本輪新merge：
- c2796e312317baaf4bdcebbb6295927b00ff364a：Lv40/metrics
- d4d5b9986fc4d8d51227566dccc7573ddbae87df：Localization/ReadModel
- f40686cda795aa61035f7473b08c8730409655b6：HUD/headless presentation
- 5349950e929546515f0669ae433beaf3c4281d63：本輪起點
本輪staging source：f16227c1e67457de53b3547a73462416c32349ef；沒有force push或PR。
正式Master push receipt：f16227c1e67457de53b3547a73462416c32349ef（5349950 → f16227c，fast-forward，ls-remote確認）。

## Tests / CI
### 重新核對的舊Master程式CI
[38718980475](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38718980475)：completed/success，受測f40686cd，M5.5完整Domain；
5349950僅其後文件/manifest變更，不能將舊CI偽稱新程式驗證。

### 本輪本地
Godot4.7.2.stable.official.ed1daf0bf，Compatibility，Windows / NVIDIA GTX1650。
- 新 test_p4_lv40_playable：32/32首輪PASS；真卡牌/M5/資源/棄牌/Full/LastSpell/Reaction/自然DEFEAT/Tape/cleanup/reentry。
- 舊Scene8、HUD36、Integration31、Component24、Feedback45、FeedbackEdges80、Staging10：全部PASS；Staging只有預期警告。
- file-only screenshot writer：首輪46執行／45PASS／1FAIL；Windows mkdir普通檔案阻擋根因已修，等待CI，不改assertion。
- 不執行GUI第四次、Lv40 domain83/edges37第四次；測試名/分支/namespace不重設預算。
原始本地logs在工作樹外：../playable-attempt1、../base-regression1、../writer-attempt1。未把歷史log/patch塞入Production Git。

### 本輪CI Gate（狀態需從GitHub回填）
- [staged full regression 38722977132](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38722977132)：completed/success。
- [staged HUD/new integration/writer 38722977144](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38722977144)：completed/success；正向32、writer46及原HUD/翻譯/投影精確Gate通過。
- [Master full regression 38726127054](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38726127054)：completed/success，1238 Domain／100 complete seeded battles+Replay／4Legacy維持。
- [Master HUD38726127041](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38726127041)：completed/success，新增正向32/32及writer46/46、既有Scene/HUD/feedback/staging/翻譯/投影通過。
- [Master Legacy38726127002](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38726127002)：completed/success。
三組受測SHA均f16227c1e67457de53b3547a73462416c32349ef。後續收據文件commit不更改受測程式；不能宣稱文件commit重新執行了測試。
保留1238 Domain、100 complete battles+Replay、4Legacy、故意失敗probe17、strict import/log gate；
HUD額外exact-count32與46。沒有用pure metrics取代研究或GUI。

## Architecture / Implemented
新增 opt-in lv40_playable_battle.tscn，舊fixture入口及lv40安全封鎖場景不改。
BattleScreen → config-aware Factory → BattleController → 現行M5 → Adapter → HUD/Director；
只Domain提交HP/AP/MP/RP/牌區/RNG/Outcome。Controller依公開requires_reaction_window安排系統命令，
不替玩家Pass。支援Full模式目標刷新、C支援LastSpell、三角/Boss/Intent/Reaction資料key。
scripts/domain相對本輪基準完全無差異。

PNG writer限制受控scope，拒絕既有檔案/目錄/namespace普通檔案，合作writer reservation，
驗證實檔PNG header/decode/dimensions、回報stage/path/error；原16項GUI輸入與oracle未更動。
不是任意不可信檔案系統的原子沙箱；外部程序無視lock/TOCTOU仍是限制。

## Screenshots / Assets
新獨立靜態scene capture（不含任何原GUI輸入案例）已實際執行並目視：
- outputs/p4_input_capture/p45_static_34392_1384350/lv40_1280.png，繁中，1280×720；
  SHA256 7030a80b1e23bfac714710818139bdbeb10ba74badd6dbde5c4b38708df8fab6
- 同目錄lv40_1920.png，英文，1920×1080；
  SHA256 b8ffe49c4c5e27aed186c3af49a1bb519729c938f5d72ecbd051dec59b3ff659
受測code f16227c，capture log在 ../lv40-static-capture2.log；未新增美術或把圖片假裝遊戲。
主控目視：手牌安全邊界／三角緊密斜排／Boss完整高度／兩語文字可見；
Boss素材仍含既有鄰角碎片，角色portrait與戰場sprite外觀映射仍placeholder，不是商用品質或正式Canon驗收。
沿用既有Kenney CC0、SimpleCards MIT、Noto OFL；其餘既有素材provenance pending，見asset_manifest/CREDITS。
沒有新插件、下載、renderer更換或重大美術採用。

## Unmerged Changes / Blockers
| 項目 | 狀態／保留方式 | 必要條件 |
|---|---|---|
| 原GUI Input 14/16 | GUI_NOT_VERIFIED，原失敗及分支保留；writer修復不等同原GUI已PASS | 用戶明確授權第四次才能重跑 |
| reviewed中的舊workflow/portable patch/logs/dispatch docs | SUPERSEDED/HISTORICAL，不merge production，原refs不刪 | 無需空merge |
| test_lv40_balance.gd／4策略×100場研究 | NOT_EXECUTED；現有policy+35metrics已在master，不將未跑研究宣稱完成 | 正式P4.5 Gate後執行版本化研究，不改批准數值 |
| 舊capture_p4_lv40_ui/feedback harness | UNVERIFIED/未採用；新靜態scene evidence不是整套替代 | 逐情境圖像/操作驗收 |
| P4.5完整人手Victory/所有技能內容parity | NOT_VERIFIED；本次32項證正向接線與自然DEFEAT，非全面可玩驗收 | 新正向真實操作/完整流程Gate |
| P4.6 GPU/真人/平衡 | NOT_VERIFIED；30profile helper只證純函式 | 指定條件benchmark、真人觀察；數值仍BALANCE_PROVISIONAL |
| 角色/Boss素材正式定稿及清權 | REUSED_PLACEHOLDER/PROVENANCE_PENDING | Major Asset Decision與權利證據 |

## Engineering Notes / Skills
詳 [positive integration note](../verification/ui/P4_LV40_POSITIVE_INTEGRATION_NOTE.md)、
[screenshot writer note](../verification/ui/SCREENSHOT_WRITE_ENGINEERING_NOTE.md)。
真實使用 orchestrator/SpecGuardian、architecture、combat、UIUX、QA；Resource/Asset skills要求先盤點並沿用現有placeholder，不新增未核准Canon。
Ownership：主控UI/Controller/CI/RTM/整合；Copernicus只寫semantic report；Fermat只寫writer/capture/helper tests/note。
主要學習：Git拓樸不等於功能缺漏（squash/blob/semantic diff）；安全負向與正向契約分離；
Godot Scene/Signals lifecycle對照Android host/StateFlow；Domain事件結果不能由動畫決定；
exit0/PASS字樣不等於無ERROR，且Headless不等於真人或GPU驗收。

## Final Status
BRANCH INTEGRATION PARTIAL — BLOCKED ITEMS DOCUMENTED。
全部已盤點分支有分類；未重複覆寫master。新的有效程式只在相關Gate成功後提升。
此結論不升級P4.4 GUI、P4.5 full playable或P4.6，不宣稱商用可售。

## 本機交付與開啟方式
隔離專案路徑：C:/Users/user05/.codex/worktrees/p4-final-integration/referenced-chatgpt-conversation-this-is-an。
Godot匯入project.godot後開 scenes/battle/lv40_playable_battle.tscn 按F6；原main仍為fixture，不暗中替換發布入口。
原使用者工作樹的8張未提交截圖未改動；新工作樹只剩Godot自動更新的SimpleCards兩個cache修改及未追蹤import/UID/本地證據，不納入本輪code/doc提交。未刪任何分支。
