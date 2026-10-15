# Battle UI Design System — V0 Draft

> **STATUS: V0 SPECIFIED / NOT RENDER-VERIFIED / TOKENS ARE PROPOSED.** 2026-10-15.
> Repo `KuroNekoLi/arbitrium-nexus-godot`；UI branch `ui/hud-visual-refactor-20261015`；branch source `master@5103e40a4b95da82f2561b29c2604e9514fd398b`。
> Visual authority: 使用者在聊天中最後核准的**較低、居底手牌**概念圖，以及既定繁中 HUD 精簡決策。原參考圖尚未作為具版本的 repo 圖檔提交；**不得宣稱完成 pixel-by-pixel 比對**。正式實作前要將經使用者核對的原 PNG + SHA-256 放入 `docs/ui/references/` 或有存取權的穩定資產位置，記錄同版 screenshots。
> 本文件為 presentation 設計，**不是玩法 ADR**；所有傷害／成本／狀態／敵方意圖／Reaction 依 `docs/combat/` 和 Domain 決定。

## 1. Art direction 與禁止事項

**方向**：dark arcane fantasy + restrained sci-fi、半透明海軍藍 HUD、細金屬描邊、青藍交互焦點、敵方威脅採暖色警示、卡牌是玩家主要操作焦點。Boss 與三名角色在中央場景呈現可讀 silhouette；大型背景與特效不能蓋掉 HUD。保留 Godot Compatibility renderer 可實現的方案；不可因 mockup 的高畫質 3D 而承諾現有 2D/2.5D 美術可直接等價。

**不要**：整張生成圖烘焙 HUD；使用舊 8 卡／自然 MP 回滿／Reaction 倒數；在底部加入牌庫、棄牌、「手牌4/8」條、另一排切角頭像；常駐固定行動順序；以視覺稿文字取代 i18n/正式角色卡片；直接替換 SimpleCards 或啟用新引擎插件。

## 2. 1280×720 設計空間（V2 起始候選）

現有 `project.godot`：1280×720、`canvas_items` stretch、Compatibility；`BattleScreen/Design` 做等比縮放。以下是**候選 Rect，不是鎖定數值／不表示已渲染**，由 Codex 以真截圖調整並回填 approved token。坐標指 `Design` 的局部空間，原點左上；所有 Rect 必須考慮真正 Control minimum size、文字與陰影擴張。

| 區塊 | 起始候選矩形 x,y,w,h | 內容／排版限制 |
|---|---|---|
| Phase+AP/RP Header | `(290, 12, 670, 64)` | 回合／階段／隊伍資源為主，設定與 Replay 做低優先次選單；不可把 AP 畫成固定上限6 |
| Party Status | `(16, 94, 260, 306)` | 3 張共用角色資訊卡，每張約 94 高；點選本身切角 |
| Command Menu | `(16, 422, 260, 276)` | Basic/Analyze/Item/Free Swap/Last Spell/End Phase；不可把免費換牌變成切角 |
| Boss HP + Break + Intent | `(978, 92, 286, 244)` | Boss 身份、HP/Break 分開、公開意圖、攻擊目標（若可見） |
| Context / Card Detail | `(978, 350, 286, 210)` | 預覽成本、模式、目標、確認/取消；可捲動／情境收合 |
| Battle Log (compact) | `(978, 575, 286, 118)` | 最近 2–3 筆摘要、詳細視窗另開；不膨脹成 debug panel |
| HandView (container) | `(286, 456, 682, 250)` | 排列以**可見卡片底緣**接近 y=700～712 為目標；不要因 container 中央置中留下 50px 空隙 |
| Conditions / buff hint | `(302, 96, 618, 40)` 或情境顯示 | 只顯示重要的選中角色狀態／詠唱／護盾摘要；可收合，不能遮住 Boss |
| Reaction modal | `(302, 154, 660, 320)` | 只在合法窗口出現，draft + reorder + confirm/pass |
| Fullscreen overlay | viewport 安全範圍內 | Casting choice、Combo、Last Spell、Battle Outcome；不擋關鍵 confirmation |

**安全界線候選**：主要互動 bounding rect 距左右邊 ≥12px；正常卡片可見底緣距下邊 8～20px，旋轉角四角須在畫面內；Hover/Selected 仍須有完整可互動區且不被 Modal 蓋住；不同卡片數量可重排，不允許單靠 clip 隱藏卡牌。

**視覺層次**：World / Actor & VFX < HUD < HoverCard & Tooltip < Contextual Modal < Irreversible Confirmation < Battle Result；按下的目標選取 hit-region 可透明，但不可攔截不相關 pointer 或覆蓋模態按鈕。

## 3. Design tokens（全部 PROPOSED / 需 screenshot 核准）

| Token | 候選值 | 用途及語義 |
|---|---|---|
| `color.bg.deep` | `#091321` | HUD 最深底，不取代場景背景 |
| `color.panel.base` | `#0F2338` | 背景基色，建議使用 0.80～0.92 alpha；實際對比需測 |
| `color.panel.elevated` | `#19354C` | Hover / selected 子區塊 |
| `color.stroke.subtle` | `#59758A` | 常態邊框，避免高亮搶視線 |
| `color.stroke.ornament` | `#B59C6D` | 少量古金屬裝飾線，非全部元件亮金 |
| `color.focus` | `#70D8F6` | Focus / Selection；同時要有輪廓／文字而非單靠顏色 |
| `color.action.ready` | `#77D9C6` | 可用操作輔助，不代表合法性最終裁判 |
| `color.intent.warning` | `#F5A883` | Boss 攻擊預告、危險，不誤導隱藏意圖 |
| `color.state.invalid` | `#9C9EAA` | 不合法／disabled，仍可閱讀原因 |
| `color.hp` | `#78D6A0` | 玩家 HP（不兼用 Barrier） |
| `color.mp` | `#6CCDFC` | 玩家 MP |
| `color.rp` | `#C6A7F7` | Enemy Phase RP |
| `color.text.primary` | `#F0F5F9` | 首要資訊 |
| `color.text.muted` | `#AFC4D5` | 次要資訊 |
| `radius.panel` / `radius.card` | `8 / 10 design px` | 卡片可稍圓，古典框角用 9-slice |
| `spacing` | `4, 8, 12, 16, 24` | 跨元件間距 scale |
| `stroke` | `1 / 2 px` | 2px 用選中/警告，正常不過亮 |
| `motion.hover` | `0.12–0.18 s` | 視覺 Tween，不影響 Command/Domain |
| `motion.reduce` | `0 s or reduced distance` | Respect reduced-motion，行動結算完全相同 |

資料色彩不等於 gameplay schema：AP 可超出6、RP 只在對應 Enemy Phase 使用、Barrier/FocusWard/Casting Stability/Break 必須分別顯示。請保持指示文字與圖像標籤，以利色覺辨識。

## 4. Typography、繁中／英文、互動命名

- 既有 `resources/ui/battle_theme.tres` 載入 `assets/fonts/NotoSansTC.ttf`；保留授權與 fallbacks，字型大小不得因 1920 版本簡單硬乘超出 Container；使用 theme type variation 避免每個節點重設字色。
- 候選 1280 設計字級：Phase 22、Boss 名稱 18、標題 16–18、卡名 15–17、資源數值 15–18、次級說明 12–14、最小互動提示 12；不得為模仿 mockup 使用難讀的極小文字。
- 所有顯示文字用 `resources/ui/battle_strings.csv` 與 `battle_translations.gd`；新增文案提供 zh_TW + en，同步測試換語系重建。
- `Hovered` 是 pointer/focus 暫時狀態；`Selected` 是已選卡且等待 target / confirmation；`Dragging` 取得局部 z-index；`Disabled` 保留可見原因，不能只變灰；`Committed` / `Resolving` 由真 Domain 結果與 Events 驅動。
- 鍵盤、滑鼠皆有 focus outline；不得透過換色把 Confirm/Cancel 觸發對象倒置。

## 5. 共用材質與 Godot 官方元件使用方向

- **Theme**：`Theme` 與不同 type variations、`StyleBoxFlat` 作底與對比，9-slice 金屬外框/角飾用 `NinePatchRect` 或 `StyleBoxTexture`，不得每張卡烘焙文字與成本。
- **已存在**：`addons/kenney_fantasy_ui_borders`、`assets/portraits`、`resources/ui/appearances/*.tres`、`addons/simple_cards`。由 Resource Manager 審權、hash、風格一致性，再決定採用；禁止整包大量下載至 repo。
- **卡片結構**：可換 `CardAppearance.artwork` + frame + independent labels/AP/MP icons；同一卡定義不同 `instance_id` 不能合併。卡片仍由現有 `BattleCardView` 維持 SimpleCards drag/click。
- **Boss HUD**：獨立 HP 與 Break 視覺條；Intent 若存在才顯示公開資料，未定義目標應顯示未知而不是推測。
- **動畫**：Card hover、選中、背景閃爍、金屬紋路與 Damage pop 為非權威；跳過動畫、降低 FPS 或關動效不能改 state / replay hash。

## 6. Card Hand 高保真規格（與既有 01 補充）

- 每名角色有獨立的真手牌；0 張呈整潔 Empty State，1 張置中，4 張可辨識插畫／卡名，8 張保持全部可選且不越界。**不呈現獨立牌庫、棄牌堆、手牌計數條。**
- 繼續使用 `HandArc.new(...)` + LayoutResult（現有 `battle_hud.gd::_arrange_hand`）；優先改 **HandView anchor/bottom alignment、content bounds + safe inset**，不要重新發明完整卡牌系統。
- 起始卡體 `164×218` design px 是現況，不是最終固定大小；卡與卡旋轉、縮放後計算 transformed corners。Selected/Hover 預期上移 **12～28 design px（起始候選）**、微放大／外光，必須同時檢查頂部不與 tooltip、左右 UI、target hit region 衝突。
- 超過4張採自適應 card gap/overlap/scale，必要時加入可訪問的捲動或檢視模式。不得偷改 Domain hand cap、不能只顯示4張並隱藏另外4張。
- Hover/Drag/取消/Release 後回到 arc pose；保留 `CardInstanceID`、owner 和 target。絕不可讓 Tween 產生第二次卡牌交易。

## 7. 狀態專用視覺處理

| Screen | 關鍵 UI | 必守行為 |
|---|---|---|
| S01 Player | AP、角色狀態、Boss intent、4張 Hand | 同一角色可連續操作；手動 End Phase |
| S02 Casting | Chantless / Full 同卡雙模式、Stability、Focus Ward | 詠唱時間/MP成本取 validator；不寫死 |
| S03 Reaction | RP、公開 EnemyAction、Guard/Protect/SP、draft queue | Queue 不扣費；明確 Confirm/Pass；**無倒數** |
| S04 Combo | Opportunity + 正常/Combo 預覽 | 第二角色合法卡真正支付；不是免費生牌 |
| S05 Last Spell | 不可逆確認、Full Chant、成功 Exhausted | 未釋放前施法者 HP0 強制失效，不聲稱死後完成 |
| S06 Outgoing/Outcome | Effect / status / result & battle log | Barrier ≠ Focus Ward；Break ≠ Casting Stability；結果只聽 Domain |

## 8. 實作前與核准門檻

1. 指定版本化參考 PNG + 來源/版號/hash；比對當下 `outputs/p4_3_idle_1280.png` 及既有 UI 實測截圖。
2. 確認所有 token 屬 **draft**；重大 UI 美術方向／資源換包用 Major Asset Decision Report，再由使用者核准。
3. V1 僅抽 Component、維持視覺與既有 APIs；V2 才套 layout，V3 才套 visual assets，不可用修改 Gameplay 取巧。
4. 每輪輸出同場景同狀態 PNG、1280/1920、中文/英文、有效/無效互動、差異說明與 rollback 方案；驗收詳見 `BATTLE_UI_VISUAL_ACCEPTANCE.md`。

**Official Godot references**：GUI Containers https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html 、Theme type variations https://docs.godotengine.org/en/stable/tutorials/ui/gui_theme_type_variations.html 、NinePatchRect https://docs.godotengine.org/en/stable/classes/class_ninepatchrect.html 。
