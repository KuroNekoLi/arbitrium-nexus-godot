# BALANCE — Lv40 deterministic balance research tools

本分支入口就是此檔；繼承的 P4_CHAT_HANDOFF.md 是其他AI的Domain任務，不是本包指令。
Repo: https://github.com/KuroNekoLi/arbitrium-nexus-godot
Branch: `handoff/p4-balance-research-chat-20261015`
Common base: `977a289654e1470bcda83c6c25c14d4cda4c86ab`。記錄開工實際HEAD；不覆蓋master或其他分支。

## 共通工程契約
先讀AGENTS、orchestrator Skill與Spec Guardian，再按本包閱讀 combat（只讀正式規則）、QA Skill及其必要references。正式Combat Spec Index／核准補充優先；UI契約不能另定玩法。工程說明與教學繁中，識別字／檔名／commit英文。
P4.4 GUI第三輪14/16、額外重跑仍待批；換分支／Agent不重設配額。共享檔只由owner寫入，不直接merge其他施工分支。僅白名單可寫；無工具則patch + NOT_EXECUTED，不虛構測試、截圖或push。新測試保存失敗log、每群組最多三次，不弱化oracle。

## 實作目標
審查並補齊已有的研究工具，不重新設計遊戲、不改Domain或平衡數值。先做統計／policy／失敗處理單元測試；真正400場要等待Domain可跑的整合commit。

## 可寫範圍
- 修改 `tools/balance/lv40_godot_policy.gd`、`tests/test_lv40_balance.gd`、`docs/verification/PH4_BALANCE_RESEARCH_NOTE.md`。
- 新增 `tests/test_p4_balance_metrics.gd`、`docs/handoff/CODEX_RETURN_BALANCE.md`。
- 研究輸出僅 `outputs/p4_balance_research/`；可新增工具專用helper於 `tools/balance/lv40_research/`。
- 禁止改其他Python balance tools、Domain、resources、Scene/UI、CI、RTM、其他fixture/runner。

## 具體要求
1. 既有driver已有BALANCED/AGGRESSIVE/DEFENSIVE/CAST_SUPPORT、paired seeds1..100、有限round/commands/events/probes及seeded replay。先讀完整driver與test，不重造。不用縮小seed數或放寬oracle換PASS。
2. 查實際M5交易、事件包裝與內容API，避免把fixture傷害或direct state mutation當成正式技能。Policy只能選合法Domain command，不供給效果值；dry-run/state hash成本可量測但不得改規則。
3. 事件統計不能雙算outer/core_event。有效heal與overheal不同；缺requested_amount時overheal應null/NOT_IMPLEMENTED，不當0。記錄已實際釋放Last／被中斷／失效、資源支出、拒絕、卡手與終局。
4. 統計mean/median/p95、勝敗率與confidence interval要有空資料/單筆/部分失敗邊界；策略比較必須同seed配對，不將失敗或timeout樣本丟掉後報漂亮勝率。
5. 研究端可以明確policy選Reaction Confirm/Pass，必須記入tape；禁止把此policy接進真人BattleController自動Pass。
6. 每場輸出seed/strategy/version/initial hash/tape/event hash/final hash/outcome/caps/replay verdict。保存最小失敗tape、截斷理由。CSV/JSON報告保留所有樣本；不把一個程序exit0當400場PASS。
7. 依存ready後才以 `--lv40-api-ready` 跑全矩陣；配置版本與初始狀態寫進報告。每測試群組最多三次，計數沿用既有已執行紀錄，parse兩輪不謊稱runtime。
8. BALANCE_PROVISIONAL不升USER_APPROVED；只報工程／策略研究觀察，不自動調Boss HP/攻擊/AP/卡費。真人playtest與核准由使用者負責。

## 依存
docs26/27/29、PH4_BALANCE_RESEARCH_NOTE、PH4_LV40_DOMAIN_NOTE。目前Domain另一分支施工；無已審核整合commit就不能報Lv40全戰鬥完成，可先交統計和工具patch及待執行命令。

## 回填格式（建立本包指定的 CODEX_RETURN_BALANCE.md）
1. Input full SHA、output SHA或patch檔名、環境、PROPOSED_PATCH / IMPLEMENTED_NOT_VERIFIED / VERIFIED / BLOCKED。
2. 逐檔NEW/MODIFY、責任／來源、unified diff及完整新檔；是否超出白名單。
3. 公開API精確簽名、schema／版本／caller changes，依存未完成列BLOCKED_CONTRACT而非猜測。
4. 實際commands／Godotversion／suite／attempt／PASS/FAIL/exit／log／seed/tape/hash；未執行明寫NOT_EXECUTED。保留歷史失敗及配額。
5. Engineering Note涵蓋目標／來源、Godot概念、責任、架構理由／替代、Android/Kotlin對照、測試方法／真結果、面試追問／延伸。
6. Codex下一步最多五項、已知問題、rollback範圍；不reset使用者資料。
有Git工具只commit/push本分支，不force、不合併master、不開PR；否則回傳patch與回填檔。工作包完成不等於P4全部驗收；Codex保留最終整合／回歸／GUI／CI責任。
