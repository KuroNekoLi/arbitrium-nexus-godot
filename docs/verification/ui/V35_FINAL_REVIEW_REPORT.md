# V3.5 Convergence — Current Review

2026-10-16。**NEEDS_REVISION — NOT HIGH-FIDELITY VERIFIED**。沒有將已合併／CI 成功當成使用者視覺核准。

## Git / runtime

- Base：`e237143d2d79590572f1d2f8aab73c25385fa55a`。
- Branch：`ui/v35-convergence-final-20261016`，獨立 clean managed worktree，保留原使用者 checkout 的 Scene／project.godot／圖片 WIP。
- HUD／手勢：`81f3d941ae033f9c6523c8fdb2e7049e4cf023d4`。
- Last Preview：`77bd22a7bcece1fc7b9cef3360aebfa5fa2dc01c`。
- 相容接線修復／最新程式：`18616633c5ba9949d9b3ef2f2c059f76a7e2a185`。後續報告提交僅文件。
- Godot 實測 `4.7.2.stable.official.ed1daf0bf`；Windows GTX1650／Compatibility；CI Ubuntu Xvfb／Mesa Compatibility。
- 未修改 V2、未 merge／push master、沒有 force push。Base..codeHEAD 的 scripts/domain diff 為空。

## 四角與新操作

| 區域 | 實作 | 未完成／邊界 |
|---|---|---|
| 左上 | 真 AP 核心／大數字／動態水晶／RP；保留三張選角卡、HP／MP／真狀態圖示 | 內部資源排版仍比參考稿垂直，需要最新圖再評 |
| 左下 | 保留圖示／副標／Last與End語義色，加入原創 NinePatch 金屬角飾、統一深色底 | Analyze／Item仍UNIMPLEMENTED；兩者並排與參考稿直向列仍有差距 |
| 右上 | 移除可見 EN／繁中／重播工具列；Boss移至右上；HP／Break獨立；公開目標徽記＋真角色atlas頭像 | 沒有猜測威力／下一招；缺Break不填假值；最終構圖未追加截圖 |
| 右下 | 「符卡詳情」只在點選／鍵盤檢視符卡時顯示，名稱／圖／Domain quote／目標／描述分層；**沒有確認／返回**；取消／出牌／換角收合 | 拖放不開詳情；普通命令不使用此面板 |
| Combat Log | 真 events→圖示／seq／敘述；所有session歷史可捲動，換語系重翻，Restart清空 | 不刪Replay；沒有偽造戰鬥紀錄 |
| SP | 合法對象放開即提交；可Full的卡按住450ms暫時Full，放開捕捉模式再復原；無效拖放不付款 | 450ms是暫定UI預設；Reaction仍手動確認／Pass |
| Last Spell | 點選即專屬cut-in／右側真報價時程／啟動取消；遮蓋戰場三人但保留隊伍欄；取消恢復、啟動才發confirmed FULL | 放大既有idle立繪，**不是新繪專用高保真CG** |

最新使用者裁決見 [Decision Record](../../ui/V35_SP_GESTURE_DECISION_20261016.md)，明確取代最初通用Action Details／常駐工具列／拖放後Confirm的部分。

## Architecture / Skills / assets

Input→BattleScreen／Controller→Factory→M5→State/Events→Adapter→HUD/Director，沒有第二套支付、傷害、HP或RNG。Last quote來自Last.inspect，targets由M5 preview取得。

實際讀取並使用：主控／Spec Guardian、UIUX、Architecture、Resource Library、Asset Pipeline、QA／CI，及新手勢的Combat Skill。遵照技能保留public facade、真quote/events、來源／失敗紀錄與測試上限；沒有因技能假設額外權限。未重做renderer，因此未另載2.5D架構技能。

新資產 `assets/ui/v35/arcane_panel.svg` 為PROJECT_ORIGINAL，SHA256 `d247ed9a7a45b6c30389f71b1cfa62a82da04f1356bacd71316e3b4470e57e7d`，已記manifest/CREDITS。Kenney CC0／SimpleCards MIT／NotoTC OFL保留。Vault環境變數未設定，選用repo既有素材，不假稱新下載、不加插件／付費服務。Last圖片使用當前Actor同一AtlasTexture，不替換正式造型。

## CI / test receipts

| Code / Gate | 實際結果 | URL |
|---|---|---|
| 81f3d94 Fast | success：Fast205；P4 1149（含convergence25）；4legacy；nativeGUI28；SPgesture17 | [38776234917](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38776234917) |
| 81f3d94 canonical Full | success：既有1238 Domain／100 seeds／Replay／4legacy；100victories、5244commands、0rejected | [38776283682](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38776283682) |
| 77bd22a Fast | **failure**：Lv40 29/32；SUPPORT-LAST-TARGET／LAST-STARTED／LAST-RELEASED；未抵達Last GUI step | [38778028502](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38778028502) |
| 1861663 Last GUI scoped | success：真滑鼠25/25，import/log errors0；Mesa V-Sync不支援warning | [38778793823](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38778793823) |

最後一列**不是完整Fast／P4回歸成功**：用盡批次的群組按明示SHA gate SKIPPED。Last為新需求獨立suite，次數headless1／native2／CI-native3。原Lv40失敗靜態修復pending_kind/legal_targets facade，未改assertions，仍IMPLEMENTED_NOT_REVERIFIED；已詢問追加一次原群組。不得把overall success當成原三個失敗已清除。

Domain原始碼未變；最新UI缺完整回歸收據。100勝僅fixture策略，不代表已核准平衡。

Raw logs位於managed worktree父目錄：`v35-ci-116564477143.log`、`v35-ci-116564477516.log`、`v35-ci-116564652690.log`、`v35-ci-116570644005-failure.log`、`last-preview-ci-3.log`；對應GitHub artifacts保存stdout/stderr。早期WIP本地測試不是最終SHA證據。

## Visual evidence / budget

原圖皆已讀像素，實際都是JPEG1280×720；A SHA256 `8505de0b9b37f0bb6c2fb7dcb1d6ab508858b8ec522d23c6543e500a32769c12`，B `0d22c6bb6c245adeb3a18b3f3bd64a107cdb9017cf485141aa4bfd2d11e1ad33`，位於docs/ui/references/v35。

真Godot capture在 `outputs/p4_input_capture/v35_final_batch1/`（45/45）、batch2與batch3（各51/51）；含1280/1920、雙語、選卡、0/1/4/8手、focus、真events／C詠唱／Lv40。人工status案嚴格MOCK_ONLY。

**三次capture都不是最新1861663**：第三批後才有右上工具列與Last cut-in新裁決；已另詢問再執行原capture一次，未獲授權前不跑第四次。歷史batch3選卡與B之並排／50%overlay／四角crop在 `outputs/p4_input_capture/v35_historical_batch3_comparison/`，compare outputs6 ok=true，不能當最新最終比對。歷史P4.4 GUI14/16未重跑，backfill超額紀錄未刪，不更名重置批次。

## Top 5 / visual gate

| Node | 實際落差／處理 | 狀態 |
|---|---|---|
| HUD/TopBar/UtilityPanel | batch3仍有工具列；81f3d94已隱藏，Boss上移 | NEEDS_LATEST_SCREENSHOT |
| HUD/Context | batch3仍有footer；81f3d94已隱藏、Idle收合，新裁決優先 | NEEDS_LATEST_SCREENSHOT |
| HUD/LastSpellPreview/CharacterCutIn | 新流程native25/25；目前只是既有立繪放大，不是精繪專用CG | NEEDS_REVISION |
| HUD/Commands/CommandContent/UtilityRow | Analyze/Item並排 vs 參考稿直向列 | NEEDS_REVISION |
| HUD/PartyStatusPanel | HP/MP排版較垂直、框材質仍比參考簡化 | NEEDS_VISUAL_REVIEW |

最新四角／六維評分 **NOT_ASSESSED**，不將舊16/24憑空改為20/24。缺最新PNG／差異註記／評分／原Lv40複驗，因此不宣告High-Fidelity VERIFIED或READY_FOR_USER_REVIEW。

## Next / rollback

取得追加授權後：原capture一次（已加入三角Last預覽及不可啟動案）、原Lv4032一次；保留所有舊logs。用最新圖做並排、Overlay、差異註記、四角／六維評分。不足門檻列NEEDS_REVISION，修改後需要重跑舊群組仍須批次授權，不暗中解除SHA gate。

專用CG新繪正式採用需資產決策／來源／回退紀錄，目前僅可替換立繪。回退使用本分支commits revert，不清除使用者checkout。Godot／Compose教學、替代方案、面試追問見 [Engineering Note](V35_CONVERGENCE_ENGINEERING_NOTE_20261016.md)。
