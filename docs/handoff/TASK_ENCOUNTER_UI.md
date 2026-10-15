# ENCOUNTER_UI — Lv40 playable UI wiring（依賴完成後接線）

本分支入口就是此檔；繼承的 P4_CHAT_HANDOFF.md 是其他AI的Domain任務，不是本包指令。
Repo: https://github.com/KuroNekoLi/arbitrium-nexus-godot
Branch: `handoff/p4-encounter-ui-chat-20261015`
Common base: `977a289654e1470bcda83c6c25c14d4cda4c86ab`。記錄開工實際HEAD；不覆蓋master或其他分支。

## 共通工程契約
先讀AGENTS、orchestrator Skill與Spec Guardian，再按本包閱讀 architecture、UIUX、combat（只整合）、QA Skill及其必要references。正式Combat Spec Index／核准補充優先；UI契約不能另定玩法。工程說明與教學繁中，識別字／檔名／commit英文。
P4.4 GUI第三輪14/16、額外重跑仍待批；換分支／Agent不重設配額。共享檔只由owner寫入，不直接merge其他施工分支。僅白名單可寫；無工具則patch + NOT_EXECUTED，不虛構測試、截圖或push。新測試保存失敗log、每群組最多三次，不弱化oracle。

## 實作目標／依存 Gate
本包依賴DOMAIN、LOCALIZATION與READMODEL三個包的穩定回填。先讀目前scene/screen/HUD並完成可逆UI準備；在沒有輸入包確切commit/API前，不可假裝正式接線完成，不自行invent新Domain/VM schema。收到三包回填後請使用者或Codex提供審核後整合commit；不要自行merge多個施工中分支。

## 可寫範圍
- 修改 `scripts/battle/battle_screen.gd`、`scripts/battle/ui/battle_hud.gd`。
- 新增 `scenes/battle/lv40_battle.tscn`、`tests/test_p4_lv40_ui.gd`、`tests/capture_p4_lv40_ui.gd`。
- 新增 `docs/verification/ui/P4_LV40_UI_ENGINEERING_NOTE.md`、回填 `docs/handoff/CODEX_RETURN_ENCOUNTER_UI.md`；logs/screenshots只在 `outputs/p4_lv40_ui/`。
- 其他檔全唯讀；尤其不可改Factory/Adapter/Translations、Domain、card_view、原scene、project.godot、CI或RTM。主入口切換由Codex驗收後做。

## 具體要求
1. 新scene重用既有battle_screen.tscn；Screen加可選encounter_profile，舊fixture預設與既有測試不變。Lv40 profile用Domain正式initial/config；重開戰鬥必須沿用當前profile，不偷偷重回fixture。
2. 用READMODEL已確定的API建立Command及VM；選角純UI、顯示真CardInstance、相同實例不重複。Actor/Boss名字從metadata key經tr，不寫死舊Kleya/Nova/Yora。
3. 卡牌casting mode、可用target、Last Spell支援型C的友軍target都從內容定義與同M5 dry-run取得；不能假設全部指向Boss、全部雙模式或全部可Combo。
4. Boss Intent顯示單體／群攻、已公開詠唱與時機。Casting Stability、HP Barrier、Guard、Break、Exposed分開，不混用50 Stability之類舊prototype。卡費由Domain內容顯示，不從CSV算。
5. 結束玩家階段交給原BattleController系統pump；合法Reaction窗口一定等玩家明確Confirm/Pass。群攻不得因UI只取target_ids[0]而提供錯誤Protect。特殊R05/T05顯示實際卡名／成本，預覽與提交都經Domain。
6. i18n新keys由LOCALIZATION包提供。若缺key，回填列出所需key與en/zh_TW文案，留給translation owner加入；不可自行改其CSV。保持減少動態／靜音設定、modal與focus生命週期。
7. 1280x720與1920x1080、0/4/8手牌、不可用卡、HP0/Exhausted、真傷害/付款/棄牌、重入與signal cleanup測試；沿用SimpleCards扇形與拖曳動畫，不另做卡牌框架。不能只交背景圖。

## 證據限制
原P4.4 GUI三次配額與額外重跑待批仍有效。不要跑其同名runner換包重設次數。新增Lv40測試只在依存已整合時執行。沒有GUI就交程式+NOT_EXECUTED，不假造截圖，不宣稱P4.5 VERIFIED。

## 回填格式（建立本包指定的 CODEX_RETURN_ENCOUNTER_UI.md）
1. Input full SHA、output SHA或patch檔名、環境、PROPOSED_PATCH / IMPLEMENTED_NOT_VERIFIED / VERIFIED / BLOCKED。
2. 逐檔NEW/MODIFY、責任／來源、unified diff及完整新檔；是否超出白名單。
3. 公開API精確簽名、schema／版本／caller changes，依存未完成列BLOCKED_CONTRACT而非猜測。
4. 實際commands／Godotversion／suite／attempt／PASS/FAIL/exit／log／seed/tape/hash；未執行明寫NOT_EXECUTED。保留歷史失敗及配額。
5. Engineering Note涵蓋目標／來源、Godot概念、責任、架構理由／替代、Android/Kotlin對照、測試方法／真結果、面試追問／延伸。
6. Codex下一步最多五項、已知問題、rollback範圍；不reset使用者資料。
有Git工具只commit/push本分支，不force、不合併master、不開PR；否則回傳patch與回填檔。工作包完成不等於P4全部驗收；Codex保留最終整合／回歸／GUI／CI責任。
