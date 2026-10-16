# Character Editor Integration — Merge Review

## 來源與範圍

來源分支 `ui/last-spell-target-scope-20261016@8430616`；整合當下 master `25612546e1522e22c82a71a693a766fea6cf5f11`。使用者於 2026-10-16 明確授權本輪忽略 30% 停工門檻、Editor／相關 Regression／GUI 各追加最多三次，直到完成 merge / push。保留歷史失敗，不消除其紀錄。

沿用正式 M5、既有 Lv40 ContentConfig 與三人 SP。沒有新增傷害引擎或修改 provisional 數值。六張生成圖為候選，不宣稱使用者已核准最終美術。

## 審查修正

- Actor 在 `_enter_tree` 恢復 Resource.changed 訂閱，離場解除；避免只依賴只執行一次的 `_ready`。
- Atlas 非等高列採各格腳底 metadata，換格時更新 Sprite offset，不移動角色 Slot；陰影固定在 Slot。三個 Actor 可各別修改位置、高度、色調與陰影寬度。
- 外觀 tint 與 Incapacitated／Exhausted tint 合成，受擊恢復時不抹掉外觀設定。
- EditorTranslationServer 與正式遊戲翻譯不同：只讀解析目錄中的精確 key，套在預覽控件，不更改共享卡牌 Resource；名字改用 Lv40 名稱 key，AP 水晶沿用正式元件的純呈現方法。
- Director 的 SceneTreeTimer 比場景長壽，單靠 generation 判斷不能立即解除等待。記錄 pending timers，在 skip／離場時先遞增 generation，再喚醒等待，使 coroutine 在原 guard 返回。新原生測試確認 windup 中離場後 pending waits 為空。首輪 convergence 25 項通過卻有 resource exit error；verbose 第二輪乾淨，仍保留首輪 log，不把非零錯誤藏在 PASS 後面。
- 新增可選、預設不啟用的第一方 `addons/editor_preview_qa`：暫時啟用並用 `--qa-editor-capture`，取得真實編輯器畫面、檢查 controller=null / snapshot empty。驗證後恢復 project 插件清單；正常開發不自動截圖或關閉編輯器。

## 本機驗證

Godot `4.7.2.stable.official.ed1daf0bf`；Windows、Compatibility、OpenGL 3.3 NVIDIA 555.99、GTX1650。

| 群組 | 本輪結果 | 次數 |
|---|---|---|
| Editor／appearance | 35/35；新增 re-entry / foot anchor 後 39/39 | 2；第3次留給專用 CI |
| M1～M5.5 | 1128 命名 assertions + 100 seeds runner 110 = 1238/1238 | 本機1次 |
| 100 seeds | 100/100 完整對局及 Replay，5244 commands | 同上 |
| Lv40 playable | 32/32 | 1 |
| Legacy | 4 suites PASS | 1 |
| V3.5 convergence | 首次25/25但離場錯誤；verbose第二次25/25無錯誤 | 2；第3次留給 P4 CI |
| 原生 scoped mouse／keyboard | 28/28 | 1 |
| 原生 SP drag／hold | 17/17 | 1 |
| 原生 Last scope／Replay | 29/29 | 1（新授權批次） |
| 新角色原生整合／截圖／離場 | 12/12；新增 pending timer 清理後15/15 | 2 |
| 真正 Editor GUI capture | 兩次成功；第二次修正翻譯key／AP水晶 | 2 |

Raw logs：`evidence/editor_merge/logs/`；成功與失敗全部保存。Screenshots：`evidence/editor_merge/screenshots/`，含1280／1920、繁中／英文、三人 Last Spell CG、真實 Basic Attack event log、Editor Scene／Last Akane。Editor 圖明確標 MOCK_ONLY；正式遊戲圖來自 Controller/M5，不是概念重繪。

命令：`Godot --headless --path . --script res://tests/NAME.gd`；原生加 `--audio-driver Dummy --rendering-method gl_compatibility` 而不加 headless。GUI input 走 Godot 原生 event dispatch；不是真人 usability test，也不是 OS 層 F6 按鍵驗收。CLI 啟動使用相同 lv40 scene。

## 教學與取捨

Resource 類似 Compose 可替換的 UI model；三個 Actor 是各自可配置的 Composable，而非三人合圖。`@tool` 的 MOCK_ONLY projection 類似 `@Preview` FakeUiState，但不建立 ViewModel／Repository／Reducer。Signal 在長壽命 Resource 與短壽命 Node 之間必須有成對連線／解線；coroutine 等待也需要取消契約，不能只取消畫面。

保留 2D＋y-sort＋不同角色大小／腳底陰影，未切換 3D renderer。Atlas 每動作三格仍屬低幀候選；不是骨骼動畫或最終高流暢度美術。Boss 仍用既有 Placeholder，沒有藉本輪定案新造型。

替代方案：每格裁成 PNG、或改用骨骼動畫會增加資產管理／製作成本；目前 AtlasTexture 與 baseline metadata 可回退，且不重寫現有演出 API。回退使用普通 revert 本輪修正與整合提交，不能 reset 其他 Agent 工作。

面試追問：為何 `_ready` 不能取代 `_enter_tree` 的重入處理？為何 cancellation 要先改 generation 再喚醒 coroutine？EditorTranslationServer 和遊戲 TranslationServer 的差異？怎麼證明預覽沒有 Domain 副作用？

## CI／合併狀態

此文件首次提交時：等待候選 CI，尚未 merge master。後續正式收據會記錄確切 SHA、Run URL 與最終結果。Commit 的 `[skip ci]` 用於避免 Push 重複消耗測試批次；實際 CI 使用明確 workflow dispatch，不降低 assertion／log gate。
