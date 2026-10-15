# Phase 4 — Visual Acceptance Checklist (human + automation)

**Checklist is NOT an acceptance result.** 本輪測試／人工截圖皆未執行；P4.4 GUI input 第三輪14/16的既有FAIL不因本工具而消失。

| ID | 檢查 | Auto oracle | Human reviewer |
|---|---|---|---|
| P4-V01 | 三人緊湊斜向層次，腳底anchor與Z順序 | 場景節點存在、位置合理 | 角色遮擋／辨識 |
| P4-V02 | Boss 兩尺寸不裁切，背景適合16:9 | 1280／1920實測 PNG 尺寸與保存status | Boss輪廓及留白 |
| P4-V03 | 0/4/8手牌在安全區，hover/drag/drop | card bounds、手牌實例去重、input logs | 卡面閱讀性與動畫平順 |
| P4-V04 | 玩家選卡/Target/Full Chant/Confirm | command receipt、卡費Domain支付、discard | 操作提示是否清楚 |
| P4-V05 | 真傷害前衝/VFX/Guard/Protect | Event cue有對應、順序不倒置 | 命中與重定向演出可信 |
| P4-V06 | Reaction窗口必須玩家手動Confirm/Pass | 沒有自動計時命令、tape中有真命令 | 互動優先級不誤導 |
| P4-V07 | Boss Intent/charge/release/AoE | 公開scope/targets與Domain等價 | 是否可讀、不可避免突襲 |
| P4-V08 | HP/AP/MP/Focus Ward/HP Barrier/Break/Exposed | 分層數值與真State核對 | 視覺區別明確 |
| P4-V09 | 中文＋英文與字串overflow | key覆蓋/切語/非rawkey，兩尺寸bounds | 文案字級與斷行 |
| P4-V10 | HP0/Exhausted／Last Spell | 禁操作、結果modal、不能重複釋放 | 警告語義清楚 |
| P4-V11 | Reduce Motion/Mute/Skip VFX | 設定切換後不改State/tape | 視覺與聽覺舒適 |
| P4-V12 | 重新開局／訊號清理／事件dedupe | controller/tape reset、signal唯一 | 不閃爍或雙播 |
| P4-V13 | FPS/Frame ms p50/p95、CPU/GPU、記憶體 | 同硬體同profile記 metadata | 拖曳與Boss特效主觀流暢 |
| P4-V14 | 素材版權與最終正式畫風 | 授權紀錄／manifest | 不將placeholder當可商售素材 |

原始證據須列 run ID、Commit SHA、Godot 4.7.2完整version、OS/CPU/GPU/renderer、locale、解析度、save_png狀態、原測試attempt/exit；不得補造或重複覆蓋P4.3/P4.4截圖。全面人工Playtest與素材採納另待使用者核准。
