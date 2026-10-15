# V3.5 SP Gesture Decision

狀態：USER_APPROVED（2026-10-16 本次使用者直接裁決）。

## 有效決策

- SPG-01：SP 拖曳至合法對象區域並放開，立即提交既有 Domain Command，不另按 Confirm。
- SPG-02：可完整詠唱的 SP，持續按住時暫時切換 FULL；合法拖放以放開當刻的模式提交，隨即恢復 CHANTLESS。無效拖放不付款，放開也恢復模式。
- SPG-03：完整詠唱「長按」目前是暫定操作；450 ms 為可替換的工程預設，不是戰鬥數值。
- SPG-04：點選及鍵盤保留目標→Confirm 的可及性路徑；Reaction 仍必須手動 Confirm／Pass；Last Spell 仍是獨立不可逆確認入口。
- SPG-05：右下名稱改為「符卡詳情／SPELL CARD DETAILS」，只有點選符卡檢視時出現；Idle、普通指令及拖放過程不顯示此面板。取消／換角／出牌後收合。Last Spell／其他指令的確認另由 `CommandConfirmation` 承載；設定與錯誤提示不屬於符卡詳情。
- SPG-06：EN／繁中／保存重播不出現在戰鬥 HUD；右上僅呈現 Boss 名稱、HP、存在時的 Break／狀態與已公開 Intent。保留底層本地化與 Tape API，不以移除按鈕刪除功能。
- SPG-07：點選終極法術立即進入專屬角色 cut-in 預覽，覆蓋左側戰場三名角色（保留隊伍狀態欄），右側顯示真實報價／釋放時程／風險與「啟動／取消」。啟動前不付款；取消還原戰場；不是符卡詳情或 SP 拖放。圖片目前沿用既有立繪作可替換展示素材，未宣稱新繪正式 CG 完成。

本決策只取代 `BATTLE_UI_COMPONENT_CONTRACT.md` §6 中「拖卡→明確 confirm」的 SP 滑鼠路徑，不更動 AP、MP、RNG、Damage、Casting 時程、Reaction 或 Last Spell 規則。歷史 P4.4 14/16 群組不重新執行，也不因此改為通過。

## 架構與驗證

SimpleCards 管理按下／拖曳／放開。BattleCardView 保存暫時手勢，HandView 轉送給既有 HUD command_requested，Screen 在放開當刻捕捉模式並產生 Command；M5 唯一決定合法性與支付。UI 的 450 ms 計時不進入 Replay；提交的 casting_mode 進入 Tape。

新增 `tests/test_p4_sp_drag_gesture.gd`：真正 Godot 滑鼠事件驗證短拖、長按 Full、無效拖放、單次提交、真實卡區交易、模式復原與 Replay。這是新裁決的新增 oracle，不是複製舊受限 GUI 群組。結果另見本輪驗證報告。
