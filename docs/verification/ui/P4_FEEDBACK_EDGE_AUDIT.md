# P4.4 Feedback Edge Audit

## 範圍與環境

- QA sidecar；僅新增 `tests/test_p4_feedback_edges.gd`、本報告及 `outputs/p4_logs/p44_edges_attemptN.log`，不改 presentation / Domain / CI，不 commit/push。
- Base HEAD：`5103e40a4b95da82f2561b29c2604e9514fd398b`；working tree 的 presentation 正由 Main 並行修改，因此 HEAD 本身不代表受測未提交實作。
- Binary：`C:/Users/user05/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe`。
- 實測版本：`4.7.2.stable.official.ed1daf0bf`；Windows / headless / project Compatibility 設定。
- Fixture：`tests/fixtures/m5_full_battle_fixture.gd`，seed `20261014`，content `m5.5-three-party-boss-fixture-v1`。全部傷害為 M5 真實命令與收據；沒有修改 live HP，所有平衡數值維持 `BALANCE_PROVISIONAL`。
- 已完整讀取 AGENTS、QA skill 及 SPEC_GUARDIAN / QA_CI_STANDARDS / CARD_COMBAT_STANDARDS、P4_TASK_CONTRACT、UI 04/05；查核 director / actor / effects / screen / controller / cue mapper 及既有 M5 fixture / runner。

## 給 Main：已重現缺陷

### P44E-REENTRY-SKIP-NO-RESUMED-MOTION

來源：UI04 §4/§9 ANIM-10、UI05 UI-I06。新 scene 的 director 以一次性 `cue_presented` 訂閱者同步呼叫 `skip_all()`，再以 `controller.submit(Factory.build(snapshot, "BASIC_ATTACK_RESOURCE_ONLY", {"actor_id":"A", "target_actor_id":"Boss"}))` 提交合法攻擊。下一 `process_frame` 檢查 actor 的 position/home 與 `motion.is_running()`。

預期：skip 的 generation 變化應使目前執行流程停止，不再啟動位移／音效／VFX。

Attempt1 / Attempt2 實際：actor motion 仍在執行，case FAIL；延後傷害已正確取消。疑似根因：`battle_animation_director.gd::_play_next()` 在 `cue_presented.emit` 後，直到第一個 timer await 之後才檢查 generation，期間仍可 `play_attack` / `sound`。請 Main 在可重入 callback 返回後驗證 generation，並保留嚴格測試。

Attempt3：Main 在 `cue_presented.emit` 返回後立即檢查 `is_inside_tree()` 與 `current_generation != generation`，本案例及 `P44E-REENTRY-NO-LATE-DAMAGE` 均 PASS；此缺陷在本 runner scope **VERIFIED / CLOSED**。

### P44E-LOCALE-{REDUCED,MUTE}-CONSISTENT-{en,zh_TW}

來源：UI05 UI-I01、UI04 §8 降低動態設定。透過 HUD 真正 CheckButton 啟用減少動態與靜音，再呼叫 `screen.set_locale("en")` 及 `screen.set_locale("zh_TW")`。

預期：新 HUD 勾選狀態與 director / overlay 的實際設定一致，Domain hash 不變。

Attempt1 實際：重建 HUD 的兩個 CheckButton 未勾選，但 director.reduced_motion / overlay.reduced_motion 仍 true，audio_enabled 仍 false；四個一致性案例 FAIL，Domain hash 案例 PASS。疑似根因：`battle_screen.gd::set_locale()` 重建 HUD 後沒有重新投影設定。請 Main 保留或投影實際設定。

Attempt2：Main 已由 director 值 restore no-signal，四個原失敗案例全部 PASS。新增 `P44E-LOCALE-RESTORE-NO-SIGNAL-{en,zh_TW}` 同樣 PASS（generation 不變）。新增 `P44E-REDUCED-PENDING-*` PASS：HUD 切至 reduced motion 立即取消 pending await，舊 coroutine 不補播傷害，Domain hash 不變。

即時交接曾嘗試向 Main task 傳訊，app 回應不允許向 native ancestor 傳訊；目前工具未暴露 native collaboration messaging。因此本共享報告與 final 是交接依據，沒有宣稱訊息已送達。

## 需求追溯與測試

| Source / authority | Case prefix | Oracle |
|---|---|---|
| UI04 §4/9 ANIM-10；P4_TASK_CONTRACT（本次授權） | P44E-SKIP / RESTART | pending await 被 generation 取消；skip 不增 late damage/idle；重啟可重用 event ID；actor 回 home；effects 清空 |
| UI04 §4 dedupe；UI05 UI-I05/07 | P44E-DEDUPE / SCENE-REENTER | pending/idle 重複事件不重播；重新進 scene 單次訊號訂閱 |
| Combat22 §2.10；UI04 ANIM-02 | P44E-INVALID | duplicate/stale command、非法目標、未知 command 整筆拒絕；hash/tape/cues/damage 不變 |
| UI04 ANIM-10；UI05 UI-I06 | P44E-REENTRY | cue signal 同步 skip 不重新啟動動作 |
| UI05 UI-I01；UI04 §8 | P44E-LOCALE | zh_TW/en 往返後設定和勾選一致、Domain hash 不變 |
| UI04 ANIM-10；本次 Main 更新 | P44E-REDUCED-PENDING | 真 HUD toggle 開啟 reduced motion，generation 增加、取消 queue、不補播舊傷害 |
| UI05 UI-I03/07；CORE-04 | P44E-INPUT | InputMap party remap 不被 install 覆蓋；內建 ui_right/ui_cancel、end_turn 生效；Reaction 下 Enter/Space/party key 不隱式結算 |
| UI05 UI-R01 / UI-B02；本次 Main 更新 | P44E-PROTECT-PUBLIC-TARGET / REACTION-TWO-COLUMN / DRAFT-LABEL | Protect option 對應 published intent；Grid 兩欄、draft Label EXPAND_FILL（結構驗證，非截圖畫質證明） |
| P1-D11/12；PRE3-R01/02；CORE-04（有效批准） | P44E-DEFENSE / REACTION | 等待不 auto-pass；Guard/Protect cue；所有 presented DamageTrace 精確等於 Domain；真正 recipient/guard_applied 正確 |
| P2-D16、CORE-03/04；UI04 ANIM-10；UI05 UI-I06 | P44E-PROFILE | 同一完整 49-command tape，在 60/10 FPS 上限、skip / reduced 下，final state hash、events hash 與重播一致 |

FPS 檢查使用 `Engine.max_fps` 上限及真實 process_frame；不宣稱每一 frame 實際穩定 60/10 FPS，也不構成 GPU / 實機畫質 profile。完整帶已含 system commands，因此透過真實 controller `_commit` 逐筆提交，避免 `submit` 再次自動調度；一般輸入／負例／Reaction 案例使用 `submit` 與 screen command 路徑。

## 執行證據

```powershell
& 'C:/Users/user05/AppData/Local/Microsoft/WinGet/Packages/GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe/Godot_v4.7.2-stable_win64_console.exe' --headless --path . --script res://tests/test_p4_feedback_edges.gd *> outputs/p4_logs/p44_edges_attempt1.log
```

Attempt1：`P4_4_EDGE_REPORT executed=64 passed=59 failed=5`，process exit **1**。原始 log 完整保留，無 SCRIPT ERROR。失敗為 reentry motion 一例與 locale consistency 四例。

Attempt2：Main 修改後增加 16 個 boundary assertions，保留原預期；synthetic key helper 同時提供 logical / physical keycode。未執行或覆寫 Main 原 45-case suite。命令同上，只更換 log 至 `outputs/p4_logs/p44_edges_attempt2.log`；開始前 SHA256 記於該 log。結果：`P4_4_EDGE_REPORT executed=80 passed=79 failed=1`，process exit **1**；無 SCRIPT ERROR，唯一失敗為 `P44E-REENTRY-SKIP-NO-RESUMED-MOTION`。runner 失敗已真實傳遞非零 exit。

Attempt3（最終，2026-10-15）：沿用同名 runner，**不修改任何 assertion 或測試程式**，runner SHA256 仍為 `639F7D912C599644A90073A59413D90F38002029C42999B1441CD6F7697B4413`。命令同上，log 為 `outputs/p4_logs/p44_edges_attempt3.log`，內含開始前 source SHA256、完整 stdout/stderr 及 process exit。結果：`P4_4_EDGE_REPORT executed=80 passed=80 failed=0`、`P44E_FAILED_CASES []`、`P44E_PROCESS_EXIT=0`。三次執行配額已使用完畢，沒有重設計數。

原 fixture 的完整命令帶有 49 筆，Attempt1 / Attempt2 / Attempt3 三種 presentation profile 皆得到：

- final state hash：`c510227726170562d623b3737226439f3dffa0e4cea1ee9dfc4150117671acdd`
- event hash：`588cb04d22911bd9d4b1a4d006eb5aa41fe2b7fa90a02a4fe879086e2928dfb1`

Guard 單獨：Boss 真實 hit 的 recipient=A、guard_applied=true，第一 hit HP100→99、第二 hit miss。Guard A + Protect B：recipient=B、guard_applied=false，第一 hit HP100→98、第二 hit miss；兩種情況 presented_damage 都與 Domain 累積 DamageTrace 精確相等，且重播 matches。這些是 fixture 限定結果，非 Lv40 parity 或正式平衡驗收。

第二次前 source SHA256（HEAD 未包含這些工作樹改動）：

| File | SHA256 |
|---|---|
| battle_animation_director.gd | D03D1B03C436D3343B5E3705E0562875B5279155283FF66CDA4DCE51D78752EE |
| battle_actor.gd | 913327AA115311A6E6288CCBCC338AC9EFCE53D0E348FDE3C306666E4F3C675E |
| battle_effects.gd | D03DCE7BDEF1A41814D8E8385C5177AD5A6AAA5E239EBA38A31EF5F04DA26276 |
| battle_screen.gd | 01CE26A90E1B8EDBAB8AE9260AB30494091FF01EAEBED01F0A954789042CAA2C |
| battle_hud.gd | 9F3FFABCB33E3A8820BDAC8D192D151E0526D2F2087AB14760BAA353C6B29B73 |
| test_p4_feedback_edges.gd | 639F7D912C599644A90073A59413D90F38002029C42999B1441CD6F7697B4413 |

Attempt3 source 差異（其餘表中檔案 SHA256 與 Attempt2 相同）：

| File | SHA256 |
|---|---|
| battle_animation_director.gd | C77F1EDAB2F4ED801515B3256A3E246641ABED769F42CAB38CDFE503CB46E7D3 |
| battle_screen.gd | E4AC3EA1CE0A278A99EF6130AB498E1EDC2A154091CF41C64D5F9F484A0FEC2A |

最終判定：**VERIFIED — P4.4 QA sidecar automated edge scope，80/80**。首輪發現的 locale consistency 與 reentry 缺陷均已在同一 runner 嚴格斷言下確認修正。沒有未通過案例。Main 的 GUI ConfirmButton Enter / focused Button Space global end_turn 優先順序，以及 Reaction modal GUI 行為仍由 Main 視窗 input suite 驗證，本 headless sidecar 不代稱通過，也不自行宣告整個 P4 已完成。

本次最終變更只有本報告與 attempt3 log；runner 沒有改動，未 commit/push。首兩輪失敗 logs 全部保留。`git diff --check` 對本 sidecar 指定兩個檔案無錯誤。

CI / GUI screenshots / 真人 playtest：本 sidecar 未執行；由 Main 整合驗收。既有 CI 目前未包含本 runner，建議 Main 在必要 gate 加上 execution + report + SCRIPT ERROR/FAIL 檢查；本 sidecar 不修改 CI。
