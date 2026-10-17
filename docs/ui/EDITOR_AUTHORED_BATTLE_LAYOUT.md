# 使用 Godot GUI 編輯戰鬥畫面

## 編輯入口與保存範圍

正式遊戲入口仍為 `scenes/battle/lv40_playable_battle.tscn`，繼承 `battle_screen.tscn`。在 Lv40 場景調整節點並存檔，會形成該 Encounter 的覆寫；修改 `battle_screen.tscn` 或共用子場景則會影響所有使用者。

常駐 HUD 已改成 `scenes/battle/ui/battle_hud.tscn`，內含真正保存的面板與彈窗實例。`battle_hud.gd` 只保留資料投影、相容欄位、訊號轉送與 modal 焦點管理。切換語言不再銷毀 HUD，也不會清除場景的位置設定。

| 想調整什麼 | GUI 中的節點／場景 |
|---|---|
| AP、回合資訊的各自位置 | `HUD/TopBar/ResourcePanel`、`PhasePanel` |
| 角色欄整組位置與範圍 | `HUD/PartyStatusPanel` |
| 每列角色欄的頭像、標籤、HP／MP 條 | `scenes/ui/hero_roster_item.tscn` |
| 角色列間距 | `PartyStatusPanel` 的 Theme Overrides → Constants → Separation |
| 指令選單、按鈕尺寸與排列 | `HUD/Commands` 或 `command_menu.tscn` |
| Boss HP、失衡與意圖面板 | `HUD/EnemyStatus` 或 `enemy_status_panel.tscn` |
| 手牌整組位置與範圍 | `HUD/HandView` |
| 戰鬥紀錄、條件提示、設定彈窗 | `BattleLogPanel`、`Conditions`、`PresentationPreferences` |
| 終式／連攜確認視窗 | `LastSpellPreview`、`ComboConfirmation` 子場景 |
| 角色在戰場的位置與大小 | `Design/Arena/A`、`B`、`C` 的 Transform |
| 角色視覺偏移、比例與整組顏色 | 角色下的 `Visuals`；動畫／立繪可分別調整 `Body`、`StateCG` |
| 角色腳下陰影 | 角色下的 `Shadow` Polygon2D |
| 角色／Boss 的可點選區域 | 各角色下的 `TargetRegion` Control |
| Boss 主體、光環與腳下法陣 | `Boss/Body`、`AuraBack`、`MagicCircle` |

## 實際操作

1. 在 Godot 開啟上述 Lv40 場景，切換至 **2D**。
2. 展開 `Design/HUD` 或 `Design/Arena`，選取目標節點。共用實例已預先開啟 **Editable Children／可編輯子節點**；若新增的實例無法展開，右鍵該實例開啟此選項，或直接開啟其來源場景。
3. 用移動工具拖動，或在 Inspector 修改 Layout／Transform。保存場景後再執行專案。
4. 要將 Boss 法陣往下移，選取 `Boss/MagicCircle`，增加其 Position Y；Boss 待機以保存的位置為基準。
5. `VBoxContainer`／`HBoxContainer` 會排列其子節點。調整它們的 Separation、Custom Minimum Size、Size Flags 和外層位置；直接拖動受 Container 管理的子節點位置，仍會被 Container 排版。

## 用 GUI 換角色欄外框與 UI

開啟 `scenes/ui/hero_roster_item.tscn`，這是三個角色欄共用的視覺模板。主要設定都在 Inspector，不需修改 GDScript。

| 修改項目 | 操作位置 |
|---|---|
| 換外框 PNG | 選取 `FantasyBorder` NinePatchRect，將圖片拖入 Texture；調整 Patch Margin 四邊以適應新框 |
| 改外框顏色／隱藏裝飾框 | `FantasyBorder` → Visibility → Modulate／Visible；程式不再改寫它們 |
| 一般、滑過、選取、焦點、失效與連攜框 | 選取根節點 `HeroRosterItem` → Skin → Panel Surfaces |
| 用圖片作整塊角色欄背景／邊框 | Skin 對應狀態建立 `StyleBoxTexture`，設定 Texture 和 Texture Margin；如不需額外裝飾，隱藏 FantasyBorder |
| 用純色、圓角、邊線、陰影 | Skin 對應狀態編輯 `StyleBoxFlat` |
| 頭像周圍的小框 | Skin → Portrait Surfaces → Portrait Normal／Selected |
| 自訂選取框顏色，不跟隨角色色 | Skin → Identity Colors → 關閉 Tint Flat Surfaces With Actor，再編輯各 StyleBoxFlat；StyleBoxTexture 一律保留自訂圖片 |
| 角色名字顏色 | Skin → Identity Colors → 關閉 Use Actor Name Color，設定 Name Color |
| 字體、字級、HP／MP 文字色 | 選取對應 Label，修改 Theme Overrides／Theme |
| HP／MP 條的底圖、填色與厚度 | `Layout/Stats/HeroHPBar`、`HeroMPBar` 的 Theme Overrides → Styles、Custom Minimum Size |
| 可行動／詠唱／失能／耗竭標籤 | Skin → Status Pills → Status Surfaces、Status Colors；保留既有狀態 ID 作為 Dictionary key |
| 連攜標記圖片 | Skin → Combo Indicators → Combo Icons；保留 IDLE／ELIGIBLE／SELECTED／UNAVAILABLE key |

預設 Skin 是 `resources/ui/hero_roster_skin.tres`。直接修改會影響所有共用它的角色欄；要製作另一套 UI，可先在 Inspector 對 Skin **Make Unique／設為獨立**，或另存 `.tres` 再指派。整個角色欄也可另存成新 `.tscn`，再到 `PartyStatusPanel` 的 **Roster Item Scene** 換成新模板。

Skin 與其 StyleBox 的修改會更新預覽；選角、狀態投影與語言切換會選用已設定的資源，避免重新生成固定皮膚。Flat 樣式的角色色功能預設保留；關閉該選項便採用資源內指定顏色。腳本只更新文字數值、可用狀態和指派對應樣式，不改動共享的 Skin 模板。

`Body`／`StateCG` 的位置、縮放與旋轉可以保存；圖片尺寸正規化與動畫腳底對齊由鎖定的 `AnimationFit`／`StateFit` 和 Sprite offset 處理。調整角色外觀來源、裁切、標準顯示高度時，使用角色的 `appearance` Resource 與 `visual_height` Inspector 欄位；SpriteFrames、texture、offset、visible 和戰鬥狀態色由程式依外觀／戰鬥資料更新。

固定指令的字級與樣式存於按鈕節點。`Commands/Auto Fit Titles` 預設開啟，會在空間不足時縮小標題；需要完全使用指定字級可關閉它。角色欄的選取、失能等樣式依 Skin 資源切換；其餘元件的資料與情境式樣式仍由對應呈現腳本管理。

`Design` 是 1280×720 的設計畫布，最外層仍會依視窗等比例縮放與置中。請調整其內的元件；這個整體縮放機制不改寫各面板／角色的本地座標。目標按鈕會追蹤各角色的 `TargetRegion`，終式標記也會轉換到正確的彈窗座標。

## 保留的動態內容與邊界

角色名單仍由 roster／CharacterDefinition 載入，角色列使用 `PartyStatusPanel.roster_item_scene` 指定的模板。卡牌、AP 水晶數量、反應選項、狀態圖示、目標卡與戰鬥紀錄依資料產生，不保存為固定的戰鬥內容。GUI 可修改其外層位置、尺寸或模板，不能藉此更改 Domain 的費用、HP、牌組或合法目標。

腳本的匯出 Node 欄位是既有控制項的綁定，改名／重排階層時須檢查這些引用；純位置與尺寸調整不需要改訊號。大幅更動節點階層仍可能需要同步更新腳本路徑。

驗收以當次分支與 commit 為準；本指南不代表 GUI 操作已驗收。回退可 revert 本次場景與腳本提交，無存檔或 Domain schema 遷移。
