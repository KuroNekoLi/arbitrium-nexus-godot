# P4 資源選型與 CGF 研究

## CGF — PROPOSED_REFERENCE / NOT_IMPORTED

使用者指定研究：https://github.com/db0/godot-card-game-framework 。2026-10-15 核對 main `f3ca9afd9705ff895839253fad208360d2f45146`。讀取 README、INSTALL、project.godot、Hand.gd、CardTemplate.gd、ADDENDUM1。不是只看搜尋結果。

功能相符：直線／橢圓手牌、懸停、重排、拖放、目標箭頭、容器／視覺狀態分離。CardTemplate 有拖曳、聚焦、重排等明確狀態；Hand 會在尺寸變動後更新位置。可借鑑互動規格，但不複製其程式碼。

相容性證據：上游 project config_version=4、Reference、PoolStringArray，Hand 使用 export/onready/yield，CardTemplate 使用 Tween node。這是 Godot 3 API，不是本專案 Godot 4 可直接匯入的 Addon。本次未檢查每個第三方 fork，沒有宣稱所有 CGF 分支都不支援 Godot 4。

## Major Asset Decision Report：框架整體採用

推薦：繼續用已匯入 SimpleCards 2.13 做輸入／拖曳基底，參考 CGF 行為但不匯入。備案一：隔離環境驗證 CGF Godot4 port；備案二：自行移植 CGF 後保留 notice 並完成授權評估。本輪不做後兩者，也不要求使用者立刻決策。

來源／授權：CGF README 標 AGPL3；ADDENDUM1 僅處理 Steamworks 互動並明示其他部分仍有原始碼供應義務，不能當作 MIT。這是上游文字核對，非法律意見。正式併入前需評估本專案散布方式。SimpleCards 2.x 正確上游 https://github.com/twdoor/simple-cards-v-2 為 MIT，補回 addons/simple_cards/LICENSE 原著作權及完整條款。原報告錯寫不存在的 simple-cards URL，已更正，未以404當作授權證明。

視覺一致：CGF demo 不是本專案美術定稿；只採用熟悉的卡牌互動，不替換 UI theme。效能：未執行 CGF，不能給 benchmark。成本：整體導入會增加 Godot3→4、autoload／scene耦合、輸入與 Domain 牌區雙重權威風險。回退：沒有匯入任何 CGF 原始碼，不影響現有相依。

具體套用：懸停卡片置頂、拖曳還原、目標合法性高亮；牌區及費用仍由 M5 決定。P4.3 依接受事件播放離手／命中演出，不能讓框架 move_to 決定真正棄牌。依使用者補充盤點，重用已有 ArcShape.compute_layout/get_layout_bounds、tween_position/tween_rotation/tween_scale；真正旋轉四角納入安全邊界。舊main.gd 也有2度／張的扇形，未刪除。沒有移植 CGF 原始碼或引入其規則DSL。

## 已取得字型 — ACQUIRED / LICENSE_VERIFIED

Noto Sans TC，官方 https://github.com/google/fonts/tree/main/ofl/notosanstc ，OFL-1.1。原檔在專案外 `C:/Users/user05/Documents/Codex/asset-vault/sources/google-fonts/noto-sans-tc/2026-10-15/`，專案 `assets/fonts/`。字型 SHA256 `864727D210D54F2537BBE23B3A839436C3992AF72DE9322AF5270897246BD44F`，11,941,968 bytes。授權 SHA256 `1C05C68C34F9708415AADA51F17E1B0092D2CEA709BF4A94CD38114F9E73D7D9`。支援雙語同字體、可回退系統字型，不重設整體美術 Canon。

既有角色／Boss／背景仍為 PROVENANCE_PENDING placeholder；本輪並無新正式造型採用。Kenney 框 CC0、SimpleCards MIT；清權狀態見 manifest／CREDITS。
