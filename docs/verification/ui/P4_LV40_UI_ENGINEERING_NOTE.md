# P4.5 — Lv40 Encounter UI reversible staging

**Status: BLOCKED_CONTRACT / IMPLEMENTED_NOT_VERIFIED / NOT_EXECUTED**（2026-10-15）。本包只施工可逆入口，**沒有把未審核的三個平行分支 merge 或把舊fixture假冒正式Lv40戰鬥**。

## 來源／依賴

`docs/handoff/TASK_ENCOUNTER_UI.md`、`docs/handoff/P4_CHAT_DISPATCH_INDEX.md` 與 `docs/combat/COMBAT_SPEC_INDEX.md`；正式 Domain、Localization、ReadModel 分別在各工作分支施工，尚無完成測試並經Codex審查的共同整合 commit，不能宣稱 Boss 完整可玩。P4.4 GUI input第三輪14/16、第四輪仍待批准。所有重大規格/Provisional Balance保持原狀。

## 本次實作

- `scripts/battle/battle_screen.gd` 新增可選 `@export_enum("fixture","lv40") var encounter_profile = "fixture"`。舊Scene完全保留fixture預設。Lv40被選時不呼叫 `Encounter.initial()`、不建立fixture Controller、HUD 終止交戰輸入，顯示既有翻譯key `BATTLE_NOT_IMPLEMENTED` 並記警告；**沒有在場景層暗中切回舊牌局**。屬等待正式介面整合的顯式BLOCKED，並非Lv40可玩實作。
- `scenes/battle/lv40_battle.tscn` 繼承現有 `battle_screen.tscn`，只切 profile，不複製整套HUD、Scene或卡框；現有SimpleCards UI保留。
- `tests/test_p4_lv40_ui.gd` 檢查新Scene確實被擋、沒有legacy State/Controller、原 `battle_screen.tscn` 保持可載入與fixture選項。**這是staging測試，不是Lv40 gameplay PASS**。
- `tests/capture_p4_lv40_ui.gd` 是獨立新GUI capture entry，必須有真Lv40 State、Controller、Config啟用才可儲存兩解析度；拒絕headless、空State與既存run資料夾，強制唯一runID。只保存真正Image、驗證尺寸與PNG寫入 Error。新資料夾限定 `outputs/p4_lv40_ui`，絕不替代或重跑原P4.4 input group。

## 待 Codex 整合後才可修改/放行

1. Domain在 `handoff/p4-lv40-chat-20261015` 的 `M5.apply` 接線先經 Godot 4.7.2 Domain/Replay/100 Seeds真測試；取得已審核SHA、穩定 `Lv40Encounter.initial(seed)/config()`。
2. ReadModel回填 `Factory.card(state,actor,instance,target,mode,combo,config)` 及 `Adapter.project(state,config)` 的確切Output Schema；Localization `Translations.install()` 真載入新兩語keys並證實。
3. 審查完前三包後由Codex做最小整合commit，確認 backward compatibility，再移除本 `BLOCKED_CONTRACT` 分支的早期return，讓明示Lv40 profile建立Lv40 initial/config、重開時保留profile而非fixture；任何改Factory/Adapter/Translations的需求都交owner，不在本branch越界。
4. 畫面擴充：從真持有CardInstance建UI、各牌合法target與chantless/full、Tsumugi Last Spell友軍target、Boss公開Intent/charge/AoE、R05/T05真Reaction Queue、FocusWard/HPBarrier/Guard/Exposed/Break分層、中文/英文、0/4/8、安全區/可及性。所有確認與preview皆走同M5；正式任務不再依硬編碼 fixture card/角色字串。
5. 有Godot GUI後執行 1280/1920、hand/refund/HP0/Exhausted、手動Reaction、Replay/tape、scene restart/signal cleanup；保留每群 1/2/3 原始log，不能假造 screenshots 或把P4.4配額洗掉。

## Godot / Android學習

`PackedScene` inheritance類似Android XML layout或Compose可重用Screen shell：同一個展示元件可由專用profile選擇資料源。與 `ViewModel`／`StateFlow`相同，場景未取得正式Domain契約時應顯示不可用，而不是產生舊的假資料去代表新功能；UI不擁有Cost/HP或自動確認Reaction。回歸測試驗證 feature-gated scene不破壞原功能。替代：複製完整場景／另建一套戰鬥Controller，但會令兩份Scene漂移、Replay不一致，因此不採用。

面試追問：「為何這不是可玩驗收？」（必要API依存尚未審查整合）。「如何避免新場景偷偷使用舊Fixture？」（顯式profile＋blocked early return＋回歸測試）。「如何在同Scene支援不同Encounter？」（stable Profile + Domain config/initial + Adapter, 而不是UI直接改State）。

**Runtime evidence:** 此聊天只有GitHub文字檔讀寫，無Godot 4.7.2執行。新Scene/測試無任何PASS聲明；GUI P4.4原先14/16歷史失敗照舊。
