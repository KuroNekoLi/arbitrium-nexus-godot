# Phase 4 — Chat dispatch index

本輪使用者授權把可交付GPT聊天的後續工作拆成獨立分支。**這是派工總表，不是已完成程式／驗收報告。** master保持原正式版本；聊天無repo/Godot權限時需附件／patch，不可假稱執行。

## 分支與入口

Repository: https://github.com/KuroNekoLi/arbitrium-nexus-godot
本總表分支：`handoff/p4-dispatch-index-20261015`。
所有新工作包從共同基底 `977a289654e1470bcda83c6c25c14d4cda4c86ab` 分出，沒有混入其他AI正在推送的Domain變更。

| 工作包 | 工作分支 | 先讀入口 | 主要owner | 依存／邊界 |
|---|---|---|---|---|
| Domain（已交付其他AI） | handoff/p4-lv40-chat-20261015 | docs/handoff/P4_CHAT_HANDOFF.md | M5/M3/M4正式接線、Lv40內容 | 不由其他包重做 |
| 雙語卡牌（已建立） | handoff/p4-card-localization-chat-20261015 | CHAT_TASK.md | translation loader、lv40 CSV、26卡面key | 不碰Domain/Screen/HUD |
| Lv40 Command Factory / Presentation Adapter | handoff/p4-readmodel-chat-20261015 | [docs/handoff/TASK_READMODEL.md](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/8b1814b8dbd4e49836a95f1a78e544de066d76bb/docs/handoff/TASK_READMODEL.md) | 見各包白名單 | 可先獨立施工；整合測試依賴Domain |
| Lv40 playable UI wiring（依賴完成後接線） | handoff/p4-encounter-ui-chat-20261015 | [docs/handoff/TASK_ENCOUNTER_UI.md](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/2034bb4294e0a7e0c780f48bf7db4f7c02a17d95/docs/handoff/TASK_ENCOUNTER_UI.md) | 見各包白名單 | 等Domain＋Localization＋Readmodel契約後正式接線 |
| Lv40 deterministic balance research tools | handoff/p4-balance-research-chat-20261015 | [docs/handoff/TASK_BALANCE.md](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/0413572a8a484d9cecd3598407a2f9a3f5d228f4/docs/handoff/TASK_BALANCE.md) | 見各包白名單 | 可先獨立施工；整合測試依賴Domain |
| Godot performance profiler / visual acceptance harness | handoff/p4-performance-qa-chat-20261015 | [docs/handoff/TASK_PERFORMANCE.md](https://github.com/KuroNekoLi/arbitrium-nexus-godot/blob/b32f8544796c8422718dbaf64bd67a525d884b07/docs/handoff/TASK_PERFORMANCE.md) | 見各包白名單 | 可先獨立施工；整合測試依賴Domain |

每個分支只新增該包派工文件，繼承的舊Domain交接只是背景。**一定讀表中指定入口，不能每個Agent都做同一套Domain。** 新包commit固定SHA如下；後續開工記錄實際HEAD。

- READMODEL: `8b1814b8dbd4e49836a95f1a78e544de066d76bb`
- ENCOUNTER_UI: `2034bb4294e0a7e0c780f48bf7db4f7c02a17d95`
- BALANCE: `0413572a8a484d9cecd3598407a2f9a3f5d228f4`
- PERFORMANCE: `b32f8544796c8422718dbaf64bd67a525d884b07`

## 可直接貼給每個聊天

> 請讀取Repository `KuroNekoLi/arbitrium-nexus-godot` 中我指定的工作分支，先完整閱讀派工總表對應的入口文件及必要Skills／規格。實作該工作包的白名單檔案，不修改其他包。不要重做繼承的Domain交接任務。完成後在同一工作分支提交，並建立該包指定的CODEX_RETURN文件，附精確diff、API、測試／未執行項目與Codex接手步驟。沒有Git/Godot就交付patch，不能稱已push或PASS；依賴未完成的正式接線列BLOCKED_CONTRACT。不要自行merge施工分支、推master或force push。

提供工作分支與入口檔即可；若它無GitHub存取，改提供該分支附件。沒有另外建立或發訊息到GPT聊天；由使用者分配。

## 整合順序／互斥

1. Domain、Localization、Readmodel分別回填；Codex核對共同base及API，最小範圍整合，不整檔覆蓋。
2. ENCOUNTER_UI可以先盤點／可逆準備，正式接線等前三包穩定的整合commit。不能猜schema或自行從變動中的分支拼裝。
3. BALANCE可先做metrics與policy測試，真400場等待Domain可用；PERFORMANCE可先寫既有scene工具，Lv40測量待UI完成。
4. Codex負責共用project.godot主入口、CI、RTM與最終驗收；任何包需要改這些檔只回填建議。
5. Domain驗收／P4.4 GUI重跑許可仍不可略過。新增分支沒有重設三次測試群組上限，不把派工、parse、headless或假資料算成視覺／真人驗收。

## 仍由Codex／使用者負責

- Review各patch、處理跨包差異、跑實機Godot、截圖／輸入、回歸／replay、commit與CI查核。
- 正式美術／重大插件／授權疑義採用、未核准玩法與數值仍需原規格或使用者裁決。
- 真人playtest、聽感／視覺品質與平衡核准不能由聊天冒稱。商售素材清權、正式export未因這次派工自動完成。
- 原使用者未提交檔、Godot產物與被後續測試覆寫的舊截圖留在本機，不混入新派工commit；不reset／force。

## 節省token的回填要求

各CODEX_RETURN只保留：input/output SHA、精確檔案、API／schema變更、diff、來源、真實測試/attempt/log、未完成項目、下一步最多五項。不要回貼全部聊天／整個repo／重複素材調研。Codex回來先讀回填與diff，只補讀受影響來源。
