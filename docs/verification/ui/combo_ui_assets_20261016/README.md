# Combo UI 候選素材整合驗證（2026-10-16）

- 分支：`asset/combo-ui-candidate-20261016`（自 `master` `090f499`）
- 素材提交：`882d068`（12 檔 SHA256 與 `assets/ui/combo/asset_manifest.json` 全數吻合）
- 引擎：Godot 4.7.2，真實視窗渲染（非 headless）
- 素材狀態：**CANDIDATE**，未定為最終美術；未修改任何 Combat Domain 規則或 combo 結算。

## 整合範圍

| 目標 | 檔案 | 內容 |
|---|---|---|
| Roster 連攜夥伴指示 | `scripts/ui/hero_roster_item.gd` | 以 `combo_partner_{idle,eligible,selected,unavailable}.png` 取代文字 Label；保留在地化 tooltip 與形狀差異（非僅顏色）。倒下角色永不顯示 eligible。 |
| 卡牌連攜框 | `scripts/battle/ui/battle_card_view.gd` | `combo_card_{eligible,selected,unavailable}.png` 覆蓋層（`MOUSE_FILTER_IGNORE`，不遮卡名/費用/插圖）；保留小型在地化狀態標籤。脈動 alpha 0.35→0.55→0.35／1.5s；Reduced Motion 固定 0.45，無縮放/位移。保留舊 `set_combo_eligible()` API。 |
| 狀態對應 | `scripts/battle/battle_screen.gd` | 僅讀取 preparation controller 推導四態／三態，不寫 Domain。 |
| Cut-in | `scripts/battle/presentation/battle_effects.gd` | 背景 → 能量 → 既有角色 CG（裁切井、半身構圖）→ 框；一般 1.4s+0.2s 淡出，Reduced Motion 靜態 0.8s+0.2s；可 skip。 |
| ComboExecuted VFX | `battle_effects.gd` / `battle_animation_director.gd` | 依已接受 receipt 的 `name_key`（`CP2_OFFENSE`/`CP2_DEFENSE`）選 sheet；256×256、4×4、16 幀、12 fps；cut-in 結束後才顯示；無全螢幕白閃；防禦屏障非 additive，保留角色輪廓。Reduced Motion 顯示靜態幀。 |
| 字串 | `resources/ui/lv40_strings.csv` | 新增 `CP2_SELECTED` / `CP2_UNAVAILABLE` 等 zh_TW/en。 |

## 測試證據

### 新增：`tests/test_combo_ui_assets_gui.gd`（真實渲染）

`COMBO_UI_ASSETS_REPORT executed=556 passed=556 failed=0`，stderr 為空。
矩陣：1280×720 / 1920×1080 × `zh_TW` / `en`，各 139 項，含一般與 Reduced Motion。

案例族：

- `UI-R01–R06`：Roster 四態貼圖、尺寸、倒下角色不可 eligible
- `UI-C01–C08`：卡框三態、對齊、不攔截輸入、卡名可見、脈動/固定 alpha、無縮放旋轉
- `UI-X00–X07`：cut-in 三層、框在 CG 之上、時長、淡出移除、CG 裁切於井內
- `UI-V01–V07`：VFX 生成、sheet 規格、無全螢幕閃光、防禦輪廓、等待 cut-in 後播放
- `UI-S00–S04`：skip 清除 cut-in/VFX 且不改 Domain
- `UI-D01–D02`：表現層不改 Domain、tape replay 一致

### 回歸

- **Headless 套件**：72 份報告，executed=3125，failed=0。
- **需視窗的 GUI 套件**（windowed 重跑）：`combo_preparation_v2_gui` 260/260、`character_visual_integration` 15/15、`p4_sp_drag_gesture` 17/17、`p4_target_arrow_gui` 19/19、`p4_target_arrow_hand_regression` 23/23、`p4_v34_gui_input` 28/28。
- **既存失敗（與本變更無關）**：`test_p4_v25_gui_input`（中途因找不到 `PreferencesDisclosure` 節點而中止）與 `test_p4_v26_pending_ux`（3 FAIL：`V26-DROP-NO-EARLY-PAYMENT`、`V26-FAN-DROP-PREVIEW`、`V26-FOOTER-ONE-TRANSACTION`）。在乾淨的 `master` `090f499` worktree 上執行，FAIL 集合與 PASS 數完全相同（v25 20/20 PASS 行後中止；v26 12 PASS / 3 FAIL）。

### 截圖（精選 16 張，完整 64 張僅本機保留以控制倉庫大小）

| 檔案 | SHA256 |
|---|---|
| `1280x720-zh_TW-02-setup.png` | `6be64ab7a55af4f43d08326439de8adb6cfaa945da692367f04df20d27e6b604` |
| `1280x720-zh_TW-03-finisher.png` | `e67fd9d6c3e8814a29c531e8938c6ec9c3bbed9987c44110d56a6d4f7d864066` |
| `1280x720-zh_TW-04-card-unavailable.png` | `198ab89a3d8d0cae2a7940ac883c63d09e109c341562e6db71baf936797038c9` |
| `1280x720-zh_TW-05-cutin-defense.png` | `f38d3c860386fad5d2dbeeec511b3d7b843d06362e728eae062cc150000427e6` |
| `1280x720-zh_TW-05-cutin-offense-reduced.png` | `de08c22e5d6f44153637c80a036b5cd4b12006dd0dc8b4d92661cee7aed4258f` |
| `1280x720-zh_TW-05-cutin-offense.png` | `43d592564cada4bf2739c2ab663d7138c178907502e8514fff4af6370f6e797c` |
| `1280x720-zh_TW-06-vfx-defense-reduced.png` | `a1d7aa776dee02b9ce4644f8a91325eca93bc1469a0cf1a947149e318ca661c1` |
| `1280x720-zh_TW-06-vfx-offense.png` | `85fddcdcaefcf50334907e445e9bbe85eba4098ca7cd2cee53a3a155244d611d` |
| `1920x1080-en-02-setup.png` | `7ba1cf0338c55e9f25654f7de46133f640eaef27a11e5cb8e0efe8c4cdd43b16` |
| `1920x1080-en-03-finisher.png` | `f67596458150d570b0b1e077dcf2d8b556e4ef3e82229009b5c738234491a140` |
| `1920x1080-en-04-card-unavailable.png` | `5db009626630424f947cc99da19650ddb7bc9185b25684a0a557b585a8151b00` |
| `1920x1080-en-05-cutin-defense.png` | `5de00d5c6b7aadbf69e629097b6b5d86e64e40f9713f5a4eb11634c004c42175` |
| `1920x1080-en-05-cutin-offense-reduced.png` | `dd8ba2a5310985e5d642b7e81707397be8ab133e03cbf5da9d515e52ef70ecab` |
| `1920x1080-en-05-cutin-offense.png` | `58d0f7ec4c922299399dfa60f54b5736156c650b8e73aedb0131e789b382afbd` |
| `1920x1080-en-06-vfx-defense-reduced.png` | `c6e1ec656d6f3913d13347dcb7626f1c5b69220154876ae2681b3140ea3eae79` |
| `1920x1080-en-06-vfx-offense.png` | `b83745c588e6d3e12a2b0d49bd43541caff8f0fbd0d6493cdcd8cb2b4b1c2055` |

重現：`godot --path . --script res://tests/test_combo_ui_assets_gui.gd`（需真實視窗；會重寫 `evidence/`）。

## 未完成／待確認

- 本報告為本機執行證據；GitHub Actions 尚未將此 GUI 套件納入（現有 CI 不跑需視窗的套件）。
- 素材仍為 CANDIDATE，最終採用需使用者核准。
