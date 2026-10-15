# READMODEL — Lv40 Command Factory / Presentation Adapter

本分支入口就是此檔；繼承的 P4_CHAT_HANDOFF.md 是其他AI的Domain任務，不是本包指令。
Repo: https://github.com/KuroNekoLi/arbitrium-nexus-godot
Branch: `handoff/p4-readmodel-chat-20261015`
Common base: `977a289654e1470bcda83c6c25c14d4cda4c86ab`。記錄開工實際HEAD；不覆蓋master或其他分支。

## 共通工程契約
先讀AGENTS、orchestrator Skill與Spec Guardian，再按本包閱讀 architecture、combat（只讀Domain契約）、UIUX、QA Skill及其必要references。正式Combat Spec Index／核准補充優先，UI文件提供呈現契約，不另定玩法。程式識別字／檔名／commit英文，教學與回填繁中。
這是使用者授權的派工，不是驗收成功。P4.4 GUI第三輪14/16、額外重跑仍待批；換分支／Agent不重設配額。僅能在白名單實作，跨scope需交接。無環境就交patch／完整新檔與NOT_EXECUTED，不假裝寫檔、測試或push。
共享Domain、translations、project.godot、CI、RTM、主整合由各owner獨占；不將其他施工分支直接merge進來。新測試保留失敗log、各群組最多三次，不弱化oracle。

## 實作目標
擴充既有 `scripts/battle/battle_command_factory.gd` 與 `scripts/battle/presentation/battle_presentation_adapter.gd`，讓正式UI可以使用Lv40內容，但不建立第二引擎、不修改戰鬥規則。

## 可寫範圍
- 修改以上兩個檔案；其他既有程式全唯讀。
- 新增 `tests/test_p4_lv40_readmodel.gd`、`docs/verification/ui/P4_READMODEL_ENGINEERING_NOTE.md`。
- 回填 `docs/handoff/CODEX_RETURN_READMODEL.md`；實際log放 `outputs/p4_logs/readmodel/`。
- 禁止改Domain、Screen/HUD、翻譯、project.godot、CI、其他runner。

## 具體要求
1. Factory.card目前硬編碼fixture definition（regular/burn/ward/regen）。新增向後相容的可選config參數；config啟用Lv40時，從真CardInstance definition產生PLAY_LV40_CARD，保留actor/card/target/mode/combo及command ID/revision，不輸入費用、傷害或效果。未啟用Lv40仍沿用fixture行為。
2. Factory.preview仍純粹呼叫同一M5；不得為預覽扣資源、抽牌或另建合法性判斷。檢查unknown/missing/foreign instance失敗契約，拒絕不得崩潰或成功偽裝。
3. Adapter.project保留原project(state)呼叫，可加可選config。沿用舊欄位語意／detached deep copy，增加資料驅動actor name key、Boss name key、公開intent顯示metadata；casting/HP Barrier/Guard/Break/Exposed是不同欄位，不互相冒充。
4. Lv40 Boss casting只投影實際已公開狀態，不把隱藏FSM、未公開弱點或未定AI數值洩漏到VM。Actor ID不是顯示字串；Adapter不呼叫tr、不用文案決定邏輯。
5. 輸出穩定介面給ENCOUNTER_UI包：精確Factory.card新增參數順序、Adapter新增keys及來源/缺省值，寫在回填。不要強迫Screen提前使用未確認的Boss schema。
6. 測試舊fixture兼容、真Lv40 instance映射、不同casting modes、unknown ID、深拷貝不可反向修改state/config、同seed preview不改state/RNG、同command schema。Domain接線尚未可用時，明確拆出投影／command shape測試；不得假造accepted receipt替整合Gate背書。

## 依存與邊界
Domain另一分支仍施工，當前共同基底新增Lv40模組尚未正式接線。先實作穩定、已文件化的command／metadata投影；需要新的runtime schema必須等待Domain回填或列BLOCKED_CONTRACT，不能猜。不得擅自merge正在變動的遠端Domain分支。參考PH4_LV40_DOMAIN_NOTE、docs26/27/29與UI02。

## 回填格式（必須建立本包指定的 CODEX_RETURN_READMODEL.md）
1. Input full SHA、output SHA或patch檔名、工具環境、PROPOSED_PATCH / IMPLEMENTED_NOT_VERIFIED / VERIFIED / BLOCKED。
2. 逐檔 NEW/MODIFY、責任／來源、unified diff及完整新檔；明列是否超出白名單。
3. 公開API精確簽名、command/event/VM欄位與缺省值、版本及caller changes；依存未完成列BLOCKED_CONTRACT而非猜測。
4. 實際commands／Godotversion／suite／attempt／PASS/FAIL/exit／log／seed/tape/hash；未執行明寫NOT_EXECUTED。保留舊失敗與重跑次數。
5. 工程Note至少涵蓋目標、來源、Godot概念、程式責任、架構理由／替代取捨、Android/Kotlin對照、如何測試／真結果、面試追問與官方延伸。
6. Codex下一步最多五項、已知問題、rollback範圍；不reset使用者資料。
有Git工具只commit/push本分支，不force、不合併master、不開PR。沒有工具就回傳patch與回填文件供Codex套用。完成工作包不等於Phase4全部通過；Codex最後整合／回歸／GUI／CI驗收。
