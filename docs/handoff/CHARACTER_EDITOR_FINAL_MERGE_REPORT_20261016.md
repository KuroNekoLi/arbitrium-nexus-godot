# Character / Editor Preview — Final Merge Receipt

## 合併

- 指定來源：`ui/last-spell-target-scope-20261016@8430616`。
- 本輪修復：`e493fd9511ba0df70bbce39cee1d6a827134f658`、`03dff9461cfa769052dc3ac49d76a48073fbcf92`。
- 同步最新 master：`c2e3152745dc6cf7d91b5845ffb2c9447c3f5c4b`（CI 排程／Legacy ownership）。
- 實際合併與 Push master：`bc057c5b419ee43bec25e5fb179e9f4dbe3f8312`。普通 merge／fast-forward push，沒有 force push、PR 或刪除分支。
- `03dff94..bc057c5` 的 scripts/scenes/assets/resources/project.godot 與相關角色／convergence 測試 diff 為空；新增的 master 工作只有 CI 與文件。

## 交付

| 項目 | 實際成果 |
|---|---|
| 角色 | A 朝霧蓮、B 九條朱音、C 白石紬，各自 Atlas／CG／Appearance Resource |
| 場景 | 獨立 A/B/C Node2D、左下→右上近距離排列、個別位置／高度／陰影／色調可編輯 |
| 動畫 | idle/run/strike 自訂列界、逐格腳底對齊、原演出 API 保留 |
| HUD | 肖像與 Last Spell CG 統一 Registry，不再從舊三人頭像合圖取得 |
| 預覽 | 真正 Godot Editor @tool、實際 HUD 元件、明示 MOCK_ONLY、不建立 Controller／Domain State |
| 生命週期 | Resource Signal 重入／解線；取消與離場解除動畫等待；base_tint 保留公開 resting-colour 契約 |
| Legacy | 舊4張 PNG 原 blob 保留，移到 assets/legacy；舊 prototype preload 更新 |
| Last Spell | 敵／我、單／全體目標、明確啟動／取消、正式 M5 效果、舊 config Replay 相容 |

SP／HP／AP／MP 等仍來自既有 Lv40 ContentConfig 與 M5；本輪沒有自行定案平衡或建立第二套引擎。

## 驗證與原始證據

- 本機 M1～M5.5：**1238/1238**（1128 + 100-seed runner 的110）；100/100 seed 完整對局／Replay；4 Legacy suites PASS。
- Lv40 playable 32/32；原生滑鼠鍵盤28/28；原生SP拖曳／長按17/17；Last scope／Replay29/29。
- 新角色原生整合15/15，含 live windup 離場後 pending_timers 為空；Editor／Appearance 第二輪39/39。
- P4 候選 CI：**SUCCESS**，[38842531426](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38842531426)，`03dff94`，25 suites /1149 assertions +4 Legacy。convergence 第3次25/25且嚴格 error gate PASS。
- Editor CI：**SUCCESS**，[38840497344](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38840497344)，`e493fd9`，39/39；此後 base_tint 合成修正由 P4 edges 原80項斷言驗證，沒有聲稱 Editor runner 在最終 SHA 重跑。
- 首次候選 Fast：SUCCESS，[38840493491](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38840493491)，`e493fd9`。
- Master Fast／Domain 收據見本文件末段；不以候選 branch CI 冒充 master 上執行的 CI。
- 首輪 convergence 離場錯誤、首次 P4 CI feedback_edges 78/80，全部原始失敗 log 保留，沒有改 assertions。

Raw logs／截圖：`docs/verification/ui/evidence/editor_merge/`。其中 `.gdignore` 只防止 QA PNG 被當遊戲素材匯入，不影響 Git 或檔案讀取。

## 視覺證據

Windows、Godot `4.7.2.stable.official.ed1daf0bf`、Compatibility／OpenGL3.3 NVIDIA555.99、GTX1650。

- [1280繁中實際遊戲](../verification/ui/evidence/editor_merge/screenshots/idle_1280_zh_TW.png)
- [1920英文實際遊戲](../verification/ui/evidence/editor_merge/screenshots/idle_1920_en.png)
- [真正Editor／三人獨立節點與Inspector](../verification/ui/evidence/editor_merge/screenshots/editor_battle.png)
- [Editor Last Spell預覽](../verification/ui/evidence/editor_merge/screenshots/editor_last_akane.png)
- [紬Last Spell／我方全體](../verification/ui/evidence/editor_merge/screenshots/last_C.png)
- [真實M5普通攻擊與事件紀錄](../verification/ui/evidence/editor_merge/screenshots/real_event_log.png)

Editor battle PNG SHA256：`8ffdae551984a24832f6fabb8079ba70976702c3188ca1c01585d852c54b2e6b`。
1280繁中 PNG SHA256：`bac674262de38db0e71f28973fdf7afd132adf96e6460f6285bd04df541794c7`。
其餘1280／1920中英文、A/B/C CG均保存在相同 screenshots 目錄；不是 AI 重繪的執行畫面。

## 開發者操作

在 Godot 開啟 `scenes/battle/lv40_playable_battle.tscn`。選取 `Design/Arena/A`、`B`、`C`，個別修改 Transform/Position、Visual Height、Shadow Width；展開 Appearance 可替換 Atlas／CG、裁切與腳底 metadata。選場景根節點的 Editor Preview Mode 可看 Battle／三人的 Last Spell。

正常開啟不啟用 QA capture plugin；若重製 Editor 截圖，暫時啟用 `addons/editor_preview_qa/plugin.cfg`，使用 `Godot --path . --editor res://scenes/battle/lv40_playable_battle.tscn --rendering-method gl_compatibility -- --qa-editor-capture`，完成後恢復插件清單。測試重跑仍受 quota 限制。

## 工程學習與限制

詳 [Engineering Review](../verification/ui/CHARACTER_EDITOR_MERGE_REVIEW_20261016.md)。`@tool` 如 Compose @Preview，但只替換 View 資料；Domain 不執行。Signal 類似 callback／Flow 訂閱；長壽命 Resource 與短壽命 Node 要成對管理。動畫 await 的取消必須解除等待，不能只有取消畫面。

候選圖不是最終 Canon；Atlas 每動作3格，不宣稱骨骼動畫流暢度。Boss 仍是既有 placeholder。沒有真人 usability／GPU benchmark／OS F6 按鍵驗收，也沒有宣稱整個 V3.5 高保真最終美術已獲使用者核准。歷史 P4.4 GUI14/16原封保留，這輪沒有重跑或冒稱清除。

## Master CI

**SUCCESS**：Fast [38843036070](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38843036070)、Domain [38843037835](https://github.com/KuroNekoLi/arbitrium-nexus-godot/actions/runs/38843037835)，兩者實際指定 `bc057c5b419ee43bec25e5fb179e9f4dbe3f8312`。Master Domain 26 suites /1128 assertions；Master Fast exact summaries／嚴格log gate通過。100 seeds／110 assertions是本機證據，不冒稱該 master workflow 有跑100 seeds。最後收據只新增文件與原始logs，沒有改動已驗證的遊戲程式。

**BRANCH INTEGRATION COMPLETE — SCOPED ENGINEERING VERIFIED / FINAL ART APPROVAL PENDING**。

### 測試次數稽核

Editor：本機2＋候選CI1＝3；convergence：本機2＋成功P4 CI1＝3（失敗P4 CI停在edges，未執行convergence）；native capture／input組皆在追加3次內。歷史P4.4 GUI沒有重跑。

流程例外：`test_m5_integration` 與 `test_m5_replay` 被本機、候選Fast、Master Fast、Master Integration重複涵蓋，實際各4次，超過本輪預定3次。這是本次CI覆蓋重疊的排程疏失，沒有額外授權，不應宣稱所有runner皆符合次數上限；保留所有Run URL，停止追加。這不改變真實PASS結果，但後續必須在dispatch前以runner而非workflow名稱去重計算預算。
