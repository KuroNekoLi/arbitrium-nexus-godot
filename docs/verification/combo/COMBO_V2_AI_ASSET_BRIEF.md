# Combo V2 — 交付其他 AI 的素材製作規格

使用者 2026-10-16 指示：新增圖片／動畫／效果先用 placeholder，再產出規格供其他 AI 製作。本輪沒有生成或下載新美術。現有 CG、卡圖、Kenney 素材保留。

## 共同交付條件

- 畫面基準 1280×720，另驗證 1920×1080；UI 由 Godot 排版，圖片不烘焙文字、費用、傷害或角色名字。
- PNG RGBA、sRGB、透明背景；不加 watermark。不覆蓋原圖。來源、作者、模型／服務、生成日期、商用及再分發權需提供 manifest。
- 建議先交單張預覽與各圖層，再交 sprite sheet；腳本、shader、執行插件不包含在素材交付內。
- 角色身分從 roster／appearance 取得。請以實際採用角色 CG 為參考，不以 slot A/B/C 假定永久人物身分。
- 主角／Boss 最終外貌及整體美術風格改版屬重大選型，本 brief 不授權最終採用。此處只做可替換裝飾。

| 資產 | 規格 | 命名／替換位置 |
|---|---|---|
| 頭像連攜標記 | 64×64；金色菱形核心、紫色細環；idle／eligible／selected／unavailable 四張；輪廓可在深色底辨識 | `combo_partner_{state}.png` → `hero_roster_item.gd` 的 ComboPartnerIndicator（目前 ◇ Label） |
| 卡牌連攜外框 | 328×436（164×218 的 2×）；中心完全透明；邊框安全區 12px；eligible 柔紫、selected 金邊、unavailable 暗紫；不可遮住卡名、原成本或圖片 | `combo_card_{state}.png` → `battle_card_view.gd`（目前 StyleBoxFlat + ◇ 標籤） |
| 合作 cut-in 裝飾 | 1180×460（590×230 的 2×）；左右角色空間各310px、中間標題520px；分離背景、金屬角框、紫色能量線；無文字、無新增角色 | `combo_cutin_{layer}.png` → `battle_effects.gd::show_combo`（目前深藍 PanelContainer + 既有 CG） |
| 攻擊連攜能量 | 每格256×256；4×4、16格、12fps；start 0–3／impact 4–11／fade 12–15；不帶背景；不得以白色閃光遮全畫面 | `combo_offense_impact_sheet.png` → AnimationDirector 接受的 ComboExecuted 事件後 |
| 防護連攜能量 | 同上；金紫雙環形成護盾，透明中心；角色輪廓不被遮住 | `combo_defense_barrier_sheet.png` → 同一事件消費路徑 |

## 動畫與無障礙

一般模式 cut-in 1.4 秒＋0.2秒淡出；減少動態模式靜態0.8秒＋0.2秒淡出，停用放大、晃動與位移。允許跳過；演出不得決定傷害、費用、卡區或行動成功。事件已結算才播放，A→B 的順序固定。

外框脈動候選：alpha 0.35→0.55→0.35，1.5秒週期；減少動態模式固定0.45。光效不覆蓋失能、耗竭、焦點環；不可只用顏色表達資格，保留圖示及雙語提示。

## 提供給圖像 AI 的基礎描述

「Dark fantasy JRPG interface ornament, restrained gold metal and soft violet arcane light, crisp readable silhouette, transparent RGBA background, no text, no numbers, no character, no watermark. Keep the middle fully transparent and preserve the specified safe area. Deliver separate layers and consistent state variants.」

每件圖片須附原始尺寸、alpha 預覽、切格座標及授權資訊。收到後走既有 Asset Manifest／Godot 匯入與兩語雙解析度真渲染檢查，再替換 placeholder；無需修改 Combat Domain。
