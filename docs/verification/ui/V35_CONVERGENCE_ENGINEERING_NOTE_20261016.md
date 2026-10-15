# V3.5 Convergence — Engineering Note

## 基準與結論

基準 `e237143d2d79590572f1d2f8aab73c25385fa55a`，工作分支 `ui/v35-convergence-final-20261016`。原 V35_AGENT_BACKFILL 的 16/24 NEEDS_REVISION 不是完成。原工作目錄有使用者資產與 Scene 修改，因此使用獨立 managed worktree；不修改 V2、不合併 master。

本輪使用者追加三個較新裁決，詳見 `docs/ui/V35_SP_GESTURE_DECISION_20261016.md`：合法 SP 拖放即提交、長按暫時 Full；右下只在點選符卡時顯示「符卡詳情」；右上移除語言與重播工具列。這些裁決優先於原 V3.5 Idle Action Details 的要求。

## 功能與責任

- `battle_hud_chrome.gd`：原創 30px NinePatch 角飾，既有 Theme 只負責深色底。Overlay 不參與來源 Texture 的 minimum-size 計算，不攔截輸入。
- `team_phase_header.gd`：真 AP 數字不封頂，水晶尺寸依槽數縮放，RP 不刪除；UtilityPanel 保留相容節點但從戰鬥畫面隱藏。
- `enemy_status_panel.gd`：只用已公開單一目標 ID 選取既有 portrait atlas；無目標／多目標時不假裝顯示單一受害者。HP 與 Break 仍是獨立資料／元件。
- `action_context_panel.gd`：符卡圖、名稱、Domain quote 成本、真實目標與效果分層。無卡時收合，不再偽裝成通用行動面板；描述可捲動。
- `BattleHUD`：保留 facade 和 public signals；設定、feedback 移出符卡詳情；非卡牌命令使用獨立 `CommandConfirmation`，納入既有 modal shield/focus 管理。
- `battle_log_panel.gd`：事件分類圖示、序號、真實事件敘述；保留所有 session rows，最新四筆與舊事件分容器，捲動可回看。換語系從完整原始 events 重新翻譯；Restart 清掉上一戰紀錄。
- `BattleCardView`：沿用 SimpleCards，450ms 是 UI 手勢預設。按住時 Full、放開時先捕捉模式再復原。Screen 只建立現有 Factory Command，Reducer 決定支付／傷害／卡區／排程。取消手勢不寫 Domain。

## 架構取捨與 Android／Kotlin 對照

Theme 類似 Compose MaterialTheme：共用字體、對比及基本形狀；StyleBoxFlat 是可配置的底材；NinePatchRect 類似 Android nine-patch drawable，只伸展非角落區域。裝飾與文字／數字獨立，可各自替換。

Container 類似 Row/Column 的 measure/layout；把大 Texture 直接加入 PanelContainer 會撐大最小尺寸，所以用沒有 minimum size 的 Control 包裝。mouse_filter=IGNORE 類似不消費 pointer event；Focus 管理相當於 FocusRequester／對話框焦點邊界。

Signal 類似 callback／Flow intent。Presentation Adapter 是 read-only UI model mapper；不是 ViewModel 中另一套可改 HP 的戰鬥狀態。與 UDF 相同：Input→Command→Reducer→State/Event→UI。動畫或 450ms 計時不決定傷害，只決定要提交哪個模式；真正模式存入 Tape，因此 Replay 不依賴機器幀率。

替代方案：整張背景烘焙 UI 無法本地化／換數值；換 UI framework 會增加拖放與 Focus 回歸風險；把 Full 切換寫入 Domain 會污染 Tape。採用小型原創 SVG + 既有 SimpleCards，沒有新插件或付費來源。

## 測試與證據邊界

測試批次最多三次（使用者本輪明示授權）；保留舊 backfill 超額紀錄與 P4.4 GUI 14/16，不宣稱已清除。新增手勢 oracle 來源是本輪 USER_APPROVED 新需求，非改名規避舊群組。

- 首批原 V3.5／V2 context／V3 integration + convergence：315/315；首批 capture45/45。
- 第二批 Fast 全部 runner：原 1124 P4 contracts 與 Fast 205 assertions 通過，另 convergence15/15；當時尚未套入最後三項 UI 裁決，不是最終 SHA 證據。
- SP gesture native GUI：前兩次皆17/17；V3.4 scoped GUI 首次28/28。
- capture 第二、第三批皆51/51；第三批完成後才收到移除右上工具列的裁決，所以不是最新工具列畫面的證據。追加一次原程式截圖驗證已另詢問，不以改名程式繞過三次限制。
- 最後 headless/GUI gate 預留給一次 CI；實際結論與 URL 以後續驗收收據為準，不預填 PASS。

畫面、raw logs 在 managed worktree 的 `outputs/p4_input_capture/v35_final_batch{1,2,3}/` 及其父目錄 `v35-final-*.log`。最後截圖及 CI 收據另補。暫不宣告 High-Fidelity VERIFIED 或 USER_APPROVED。

## 整合收據與新終極法術需求

`81f3d941ae033f9c6523c8fdb2e7049e4cf023d4`：Fast Actions [38776234917](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38776234917) completed/success；205 Fast + 1149 P4 assertions、4 legacy suites、GUI28、SP gesture17。完整既有 Domain/100 seed [38776283682](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38776283682) completed/success；100 runs、100 victories、0 rejected、5244 commands、100 distinct tapes，僅證明固定 fixture，不是零敗率平衡。

後續依本輪新裁決增加 `last_spell_preview.gd`：點選即開 cut-in，角色圖使用當前 Arena 的同一 Texture2D idle frame，不新增正式角色造型；戰場三人暫時隱藏，隊伍狀態欄仍可讀，取消／提交恢復。`Last.inspect` 提供真報價及 delay；合法 targets 由 M5 preview 取得，預選 Boss 但允許查看其他合法 target。只有「啟動」才送 confirmed FULL Command。headless 首次25/25，native GUI 第二次25/25（三名角色開啟／取消與啟動皆經真正滑鼠事件），第三次留給 CI。

新需求發生在原 V3.5 CI 第三次執行後；因此本工作分支後續 push **不再重跑已用盡的 P4-contracts/V3.5/手勢群組**。CI 加明示 SHA gate；其他分支 canonical gate 保留，不刪測試或放寬 oracle。新 Last Preview 25-case suite 是新裁決獨立需求，不是複製舊群組。最終截圖仍需追加授權；不能用新 renderer 名稱或新分支重置截圖批次。

## 面試追問與延伸

最新追加預覽 Commit `77bd22a7bcece1fc7b9cef3360aebfa5fa2dc01c` 的 [CI 38778028502](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38778028502) **failure**：Lv40 32 項為29/32，失敗 `P45-SUPPORT-LAST-TARGET`、`P45-LAST-STARTED`、`P45-LAST-RELEASED`。根因是新 cut-in 未同步公開 `pending_kind`／`legal_targets` facade，非 Domain 內容變更。保留原始 log：managed worktree 父目錄 `v35-ci-116570644005-failure.log`。修復同步真實 target ids，舊程式客戶端的 select_target/confirm_action 仍走同一 Factory；GUI 仍僅顯示 cut-in 的啟動／取消。不修改任何原 assertions。

Lv40 群組已達本輪三次，因此修復後原群組狀態仍 `IMPLEMENTED_NOT_REVERIFIED`，已另詢問一次追加授權。該 CI 在抵達新的 Last native gate 前失敗，故 Last suite 仍是 headless1/native2，尚可執行第3次。不得把 CI 未執行的 Last gate 說成已失敗或已通過。

1. 為何 Command 有 expected_event_seq？防止 stale UI 對新版狀態重複付款。
2. 為何拖放後先擷取 Full 再 reset？手勢狀態不是結算狀態，過早 reset 會把合法 Full 變成 Chantless。
3. 為何隱藏而不是刪除 public facade？小步遷移，讓現有 Controller／測試仍指向同一真元件。
4. 為何不能用 headless PASS 當視覺 PASS？measure 和實際字形／GPU 裁切是不同證據。

官方學習入口：Godot `Control`、`Container`、`NinePatchRect`、`BaseButton`、`Signals` 與 `Theme` class reference（docs.godotengine.org）。回退：revert 本輪分支提交；不 reset 使用者 checkout。
