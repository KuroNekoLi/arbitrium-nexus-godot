# Combo Preparation V2 工程紀錄

日期：2026-10-16（Asia/Taipei）。**實作已交付；Domain／GUI 驗收暫緩，未宣告完整完成。**

## 來源、範圍與版本

- Repo：KuroNekoLi/arbitrium-nexus-godot；branch `feature/combo-preparation-v2`；base `50bf7b19b2f9c3d66c1a8cd267bd20ef7f56b4cd`。
- Godot：`4.7.2.stable.official.ed1daf0bf`；本機 binary：`C:/Users/user05/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe`。
- 授權：本次 Combo UI/UX V2 任務及使用者新增「先 placeholder，再寫規格交其他 AI 製作」指示。數值／配方仍屬候選。
- 開工 fetch 後 base 與 origin/master 相同。未提交的 SimpleCards layout cache／IDs、project.godot、既有 staged 平衡報告及其他 handoff 檔均未納入本次 commit。
- 依 [ADR-001](ADR_001_PREPARED_COMBO.md) 保留 M1–M5、正式12 SP、原有 AP/MP、詠唱、Reaction、終式規則。
- 箭頭重用 `origin/poc/card-targeting-arrow-20261016`（tip `9f73140`）的 overlay 與接線概念；未整分支合併或覆寫其他 Agent 分支。

## 玩家可操作流程

1. 點擊 Setup SP：只保存 actor／CardInstanceID，顯示潛在搭檔；仍可單獨普通拖曳施放。
2. 點擊高亮頭像：保存 A，切換到 B 原有手牌；合格 Finisher 加紫金框及文字標記，原卡名／圖／成本／ID 不變。
3. 使用原 SimpleCards drag。箭頭與合法目標沿用既有 hit regions。放在合法目標後開啟比較，尚不扣費。
4. 比較窗明示「普通僅 B」與「A→B」；Setup 目標與 Finisher 目標分開。防護配方需明確選 Setup 友方，攻擊配方依正式規則要求共同敵方目標。
5. 普通只提交 B；連攜提交版本化複合命令。取消確認回到可繼續選牌；Esc 可取消預備。
6. 合作 cut-in 只消費成功事件，使用既有角色 CG 與可替換 placeholder；事件演出依 A→B 分組。

## API 與檔案職責

| 檔案／API | 責任 |
|---|---|
| `scripts/domain/m5/combo/prepared_combo_resolver.gd::resolve` | 複合命令隔離驗證、兩次原 Resolver、Opportunity／Bonus／目標與角色規則 |
| `Prepared.potentials / quote / recipes` | 純查詢潛在配方、原 M2 費用、兩種現有候選配方；不建立真 Opportunity |
| `lv40_domain_extension.gd::apply` | 驗證 schema／revision／duplicate 後路由新命令；舊單卡解碼保留 |
| `scripts/battle/combo_preparation_controller.gd` | 暫存兩張卡、兩組 targets、recipe、revision 與未提交狀態；沒有 Domain 寫入權 |
| `scripts/battle/presentation/combo_preview.gd::compare` | 使用真 M5 detached preview 比較普通／連攜；A 執行後才查 B 的動態成本 |
| `scripts/battle/ui/components/combo_confirmation_overlay.gd` | 可重用雙欄 modal、兩個頭像、Setup 目標與 Recipe 選擇、三個按鈕 |
| `battle_card_view / hero_roster_item` | 連攜標記及外框；不覆蓋耗竭／失能，不重命名 CardDefinition |
| `battle_screen.gd` | 選取、拖放、比較與 Controller glue；HUD 仍只作組合 facade |
| `battle_animation_director / battle_effects` | 成功事件後依序演出及 placeholder cut-in；不控制傷害 |

本次**沒有新增或替換 Scene 檔案**；重用 `lv40_playable_battle.tscn` 和既有 HUD／手牌場景，新增元件由 GDScript 組合。

## 複合提交、成本與原子性

命令 `COMMIT_PREPARED_COMBO_V2` 包含 `setup_actor_id`、`setup_card_instance_id`、`setup_target_ids`、對應 finisher 欄位、`recipe_id`、`command_id`、`expected_event_seq`。目前每張卡是一個 target anchor；不接受呼叫方傷害、成本、buff 或 RNG 數字。

外層驗證後，以 detached snapshot 呼叫既有 `Lv40.apply` 執行 A。必須真正建立本次所需 Opportunity；接著以 A 結算後的狀態重驗並執行 B+Bonus。B 失敗、A 未建立 Opportunity、A 殺死最後敵人、角色失能或目標失效等，全部回傳原 snapshot、空 events、原 state hash。不退款補償，因為正式狀態從未部分提交。

成功保留 A→B 的所有付款、傷害、Break、狀態、RNG 與 action boundary 事件。一般連攜額外 AP=0。UI 的 AP 合計來自 Domain 提供的兩次 Cost Engine quote；MP 分角色呈現，避免共享資源錯覺。效果顯示真 preview events，沒有 UI 傷害公式。

舊 Setup→Opportunity→Finisher 指令／Replay 不變。新命令內部 ID 為 `外部ID:setup`、`:finisher`，外部及內部 seen IDs 都保存。相同 snapshot／seed／命令確定性重播；預覽及失敗候選不消耗正式 RNG。

## 驗證紀錄與驗收決定

原始 log 存在 `evidence/logs/`；截圖為真 Godot viewport PNG。這些是腳本送入真 Godot GUI 的滑鼠事件，走 GUI picking／SimpleCards／Controller／Domain，**不是人類真人試玩認證**。Fixture 明確標示測試用卡區交換／CORE_OPEN，沒有修改正式初始戰鬥或暗中注入額外卡。

| 群組 | 實際結果 | 狀態 |
|---|---|---|
| 開工 baseline Lv40 | 83/83 | VERIFIED，限 baseline |
| 新 Domain 第1輪 | 測試 fixture 缺 retired map，執行中止 | 保留失敗 log |
| 新 Domain 第2輪 | 140/140；100 seeds 防護配方 | 當輪 VERIFIED，不能代替後續版本 |
| 新 Domain 第3輪 | 136/142；擴充攻擊 seed 後6個 Setup 隨機 miss，被測試錯誤要求必成功 | **修正測試 oracle，未重跑；驗收暫緩** |
| GUI 第1輪 | 181/208；箭頭重建接線、焦點、測試目標索引問題 | 保留失敗 log |
| GUI 第2輪 | 204/208；Windows cursor 延遲、英文點擊座標排版時序 | 保留失敗 log |
| GUI 第3輪 | 258/260；兩語兩尺寸、選取／切角／高亮／箭頭／比較／取消／普通／MP不足均有證據；英文兩尺寸連攜按鈕測試未通過 | **GUI 暫不驗收** |
| 舊 Combo | 44/44 | VERIFIED，本輪回歸 |
| 舊 Replay | 15/15 | VERIFIED，本輪回歸 |
| Lv40 Domain／edges | 83/83、37/37 | VERIFIED，本輪回歸 |
| 雙語／手牌／角色欄 | 198/198、39/39、57/57 | VERIFIED，本輪回歸 |
| Lv40 playable integration | 32/32 | VERIFIED，本輪回歸，非完整真人操作 |
| 新分支 CI | import／parse only | **不代表 Domain／GUI PASS**；URL 見 CI_STATUS.md |

**使用者驗收指示（2026-10-16）**：詢問超過 Skill 每群組三輪上限時，使用者選擇「保留三輪結果，GUI 暫不驗收」；另對 Domain 選擇「保留結果，不再重跑 Domain」。因此沒有進行第四輪，也沒有讓 CI 偷跑第四輪。英文 GUI 測試已補 Container 排版等待，但未執行修正後版本。Domain 測試已改為同 seed 成功／拒絕結果及 state/event hash 一致，拒絕必須原狀態不變；不把隨機 miss 變為強制命中。

36張 PNG 覆蓋兩語、1280×720／1920×1080。`*-en-06-cooperation-placeholder.png` 是**未成功提交的失敗證據**，不可當成英文成功 cut-in；繁中對應圖有真成功 cut-in。其他圖的完整清單、尺寸、SHA256 見 `EVIDENCE_MANIFEST.json`。

## 未完成與不宣稱的內容

- **C2.7 未完成**：修正後 Domain／英文 GUI 未重跑，沒有新功能完整綠燈或真人整場 Boss 通關。
- CP2-21～23：查詢／清單／Recipe 選單支持多筆資料，但目前兩種配方及 starter hand 沒有完整多搭檔／多 Finisher／多 Recipe fixture 驗收。
- CP2-25／27 與多敵人畫面：目前 Lv40 是單 Boss；沒有正式全體連攜配方，不能偽造已支援。不同卡保留不同 target arrays，目前各一個 anchor。
- Full Chant／CastingCombo／Last Spell 共鳴不接入瞬發 Preparation；保留既有獨立施法／終式流程。
- 合作演出屬 placeholder，角色專屬新 VFX 尚未製作；交給其他 AI 的規格見 [AI 素材 Brief](COMBO_V2_AI_ASSET_BRIEF.md)。
- 卡牌0～8張本輪39項 headless 手國牌扇回歸通過；不能推論所有尺寸的8張真人拖曳已驗收。

## 架構學習與替代設計

本功能示範如何把「玩家正在考慮的選擇」與「已發生的戰鬥事實」分開；Control／signal／focus 負責互動，Dictionary snapshot／Reducer 負責規則。把 UI query 和 command 共用真 Resolver，可避免預覽與實際費用漂移；深複製候選狀態保證 RNG、卡區及事件一起隔離。動畫從 accepted receipt 消費，省略動畫也不改結果。

未採先扣 A 再退款的補償設計，因為無法可靠撤銷 RNG、Boss Break 與觸發。未採另一套 Card Drag Controller，以免手感、輸入和焦點互搶。未建立獨立 Combo 普通卡牌，也沒有把 Finisher 改名。回退可 revert 本分支程式 commit，既有 Scene、素材及舊 Replay 無須遷移。
