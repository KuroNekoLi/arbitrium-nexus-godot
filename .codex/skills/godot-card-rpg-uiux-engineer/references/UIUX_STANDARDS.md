# 卡牌 JRPG UI/UX 規範

先讀 Spec Guardian。Combat Engine 是唯一權威；UI顯示狀態、quote及理由，提交command後依結果更新，不自行修改cost／damage／卡區。現有card_view與simple_cards先確認功能與ownership，再擴充adapter。

## Layout與資訊

HUD優先Control、Containers、Anchors、Size Flags、Theme；不要大量固定絕對座標。扇形手牌可有專用layout，但要明確最小卡寬、間距、遮擋／focus擴張、resize與縮放策略。Container控制的layout wrapper不直接被hover tween競爭，內層視覺節點可動畫。

Battle HUD包括角色HP/MP／狀態、全隊AP/RP、敵方HP/Intent／狀態、回合／phase、手牌owner、target、結果與錯誤。timeline僅顯示Domain提供的順序，不能猜未公開AI資訊。menu／inventory／progression／角色互動與對話採同一Theme和輸入／本地化契約；不為畫面自行新增裝備或成長規則。

每張卡顯示名稱、費用、類型、效果、owner、可用與不可用原因、目標；分清Hover/Focus、Selected、Targeting、Resolving、Disabled。費用或效果因狀態改變時重新quote，舊preview綁state revision。無效提交以本地化reason解釋，恢復合理focus與選取，避免重複送出。

## 操作狀態與可及性

mouse hover／click／drag and drop與keyboard focus都需能選卡、選目標、取消、確認。gamepad/touch僅在支援平台已納入時驗收，不默默擴張scope。drag threshold、防誤觸、拖出區域、hover遮擋、mouse_filter、gui_input／unhandled_input衝突明確處理。取消未提交選取不扣費；提交後取消是否允許依規格。Reaction queue允許確認前調整，合法窗口沒有自動倒數或auto-pass。

焦點鏈與focus neighbor可預期；card移除後focus遷至合理下一項。modal關閉恢復原focus，Tooltip有鍵盤等價。用圖示＋文字傳遞狀態，不能只靠顏色；檢查對比、可讀字級、減少動態與shake選項。快捷鍵使用Input Map，語言切換不改command ID。

## 繁體中文與英文

玩家可見文字使用正式Translation管線（沿用專案CSV／PO／Translation resource），包括Tooltip、卡名／描述、失敗理由、對話、狀態、選單、動態數字模板。建議一致key如 `BATTLE_ERROR_INSUFFICIENT_MP`，資料保留key，不拿顯示字串判定card或status ID。

`tr()`／需要複數時`tr_n()`及具名placeholder依實際版本與既有管線使用。不要靠片語串接假設所有語序相同。locale可採既有的zh_TW／英文設定；字型需有繁體字形並記授權，fallback與缺字檢查。測試兩語長字串、換行、ellipsis、動態字級與數字、卡片Tooltip邊界、執行時切語言及export翻譯資源是否包含。所有玩家文字不得無條件硬編碼。

## UX驗收腳本

用明確scenario讓玩家辨識現在輪到誰、可執行什麼、為何不能用、目標是誰、效果preview與行動後變化。測三角色手牌切換、資源不足、失效目標、Reaction排隊／Confirm／Pass、skip演出、戰鬥結束輸入鎖定。檢查狀態與權威snapshot一致；以截圖／錄影＋event log記錄，未實玩則標NOT_EXECUTED。華麗特效不能遮蔽費用、目標和結果。

官方依據：[Containers](https://docs.godotengine.org/en/4.7/tutorials/ui/gui_containers.html)、[Internationalization](https://docs.godotengine.org/en/4.7/tutorials/i18n/internationalizing_games.html)。
