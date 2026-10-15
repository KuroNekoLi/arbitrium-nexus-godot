# Lv40 Positive Scene Integration — Engineering Note
日期：2026-10-15；狀態：本地正向32/32，最新修正等待 branch/master CI。不是 P4.5 全量或真人驗收。

主控續記：staged full38722977132及HUD38722977144均completed/success；source f16227c已fast-forward到master。新正向32及writer46精確CI Gate通過；正式Master CI待核對。補拍p45_static_34392_1384350兩語兩尺寸並目視，Boss標題已正確使用config名稱，hash及路徑見最終整合報告。

## 1. 目標與來源
正式Master驗證續記：source f16227c，Actions38726127054／38726127041／38726127002均success；32項正向及46項writer通過，1238 Domain與100Seeds保持。只提升本次技術整合scope，不是完整P4.5/真人Gate。
使用者 All Branches Review / G4 指定把現行 M5 Lv40 Content 接入真正場景；遵守 COMBAT_IMPLEMENTATION_CONTRACT §2、UI02、Phase4 Handoff。原 lv40 staging 負向測試保留不變，不把封鎖期望改成成功。

## 2. Godot概念與責任
- 新 scenes/battle/lv40_playable_battle.tscn 繼承原 BattleScreen，使用新 lv40_playable profile；fixture 與 lv40 staging 都保留。
- BattleScreen 組合真 Lv40Encounter.config/initial，所有 CardInstance 使用 Factory.card(...,config)，Adapter.project(...,config)。
- 選角純UI；模式改變重新預檢目標；Last Spell 的合法目標由同 M5 preview 決定，支援 C 的隊友施放。
- BattleController 只推動 Domain 公開排程；Boss 已宣告不需 Reaction 的動作直接結算，不新增 AI 或自動 Pass。
- Party/Boss/Intent/Reaction名稱走 config key；沒有第二套 HP/AP/MP/卡區/傷害/勝敗。
- Director/Tween 仍只呈現已結算事件；本輪不重新做動畫框架。

## 3. 架構選擇與替代
新增 opt-in profile 而不刪 staging，是保留安全負向契約並新增獨立正向契約。替代方案是把原 lv40 profile 改活，同時修改原負向tests；那會失去「無有效接線不可偷用fixture」的安全覆蓋。
Controller 原本為每個 active action 嘗試開 Reaction，Lv40 的 B05/B07/B08/B10 等無攻擊公開動作不應走該入口；直接依 public_intent.requires_reaction_window 而非猜 skill ID。

## 4. Android/Kotlin對照
BattleScreen≈Fragment/Compose host；Controller≈單向ViewModel action dispatcher；
M5 Reducer≈StateFlow唯一更新者；Adapter≈不可變UI model；signals≈callbacks/Flow；
PackedScene繼承≈可重用UI組件。不要在動畫結束listener改業務state。

## 5. 測試與證據
新 test_p4_lv40_playable.gd 首次32/32：三人各12真SP/起手4、資料名稱、純UI切角、
真 PLAY_LV40_CARD→preview/commit parity→AP付款/Discard、重複拒絕原子性、Full Chant、
手動Reaction等待、跨回合、支援Last Spell→Exhausted、自然DEFEAT、Tape檔重播、cleanup/reentry。
本地原P41 8、P42 36、P43 31、component24、feedback45、edge80、staging10均PASS；staging有預期BLOCKED_CONTRACT warning，非新錯誤。
沒有執行已用盡的 Lv40 domain83/edges37 或原 GUI Input。
所有原始本地logs保存在專案外 ../playable-attempt1、../base-regression1、../writer-attempt1，沒有加入production Git。

PNG helper 首輪46 executed /45 PASS/1 FAIL：namespace為普通檔案時某Windows backend遞迴mkdir回OK，實際於reserve失敗。已加 FileAccess.file_exists(directory) 前置拒絕，不修改 SW-16 oracle；修正後交由CI執行。

## 6. 真實畫面與素材
新 capture_lv40_playable_scene.gd 只載入正向場景並靜態截圖，不模擬鍵鼠，不複製原16項GUI測試。
實際 Godot4.7.2 / OpenGL3.3 / GTX1650：outputs/p4_input_capture/p45_static_39580_1418414/lv40_1280.png（繁中）、lv40_1920.png（英文）；PNG解碼/存在/尺寸驗證成功，主控已目視。拍攝在Boss title資料key修正之前，舊標題已列已知差異。
畫面有三人緊密斜向排列、Boss完整高度、四張真手牌與未啟用卡理由；不是完整GUI輸入/動畫/可讀性驗收。
Resource/Asset Skills導向既有素材重用，不下載：Kenney frame/VFX/SFX CC0、SimpleCards MIT、Noto TC OFL。既有角色/背景/card atlas仍 PROVENANCE_PENDING / REUSED_PLACEHOLDER，沿用 assets/asset_manifest.csv，沒有將正式外觀冒認核准Canon。

## 7. 限制、回退與待辦
開啟新scene後F6或CLI指定場景即可，不更換 project.godot main，避免把尚無真人驗收的demo默認發布。
未完成真人勝利對局、全部技能內容parity、完整Boss視覺動畫、400場研究、GPU benchmark；正式BALANCE_PROVISIONAL不變。
原GUI14/16及第四次禁令不變。新靜態截圖/純檔案helper通過不能宣告原GUI已修好。
回退只撤銷新增profile/scene及config-aware接線，既有Domain與staging保留。

## 8. 面試追問與學習資源
- 為何preview與commit使用同Reducer，仍需expected_event_seq？
- 為何「沒有合法Reaction」與「玩家Pass」不同？
- 如何證明scene重建沒重複signal，而不只看畫面？
- Hash相同為何不能證平衡或美術品質？
延伸：本專案 architecture Skill 的 GAME_ARCHITECTURE、Godot官方 Scene organization/Signals/Containers，
QA Skill 的分層Gate與 Deterministic Replay；上述參照檔含官方連結。
