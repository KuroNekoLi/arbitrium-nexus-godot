# Battle UI Visual Acceptance — V0 test matrix / gate

## Current runtime reacceptance — 2026-10-17

Reviewed on `master@481cf8bfdd2baa0326829dfc6d4b2a7c5702b219` with Godot `4.7.2.stable.official.ed1daf0bf` in a disposable Windows checkout. Current Lv40 HUD/hand/roster/command/Last Spell surfaces are still used by the playable battle, so V2/V3/V3.5 component behavior was rechecked as one current-runtime scope; historical stage snapshots are not separate acceptance gates.

- Current P4 UI contract suites: **25 suites, 1,149/1,149 assertions PASS**.
- Real-render capture: **63/63 checks PASS**, 18 captures across 1280/1920, zh_TW/en, hand sizes and Lv40/Last Spell previews. This verifies rendering and bounds, not final art approval.
- Current playable-battle integration: `test_p4_integration` **31/31**, `test_p4_lv40_playable` **32/32**, character state CG **39/39**, spell/character presentation **46/46**, targeting contract **26/26**.
- Real GUI: V3.4 roster/command input **28/28 PASS**. The old V2.5 runner stops after its first 20 passing mouse/keyboard checks because it looks up preference controls at obsolete node paths; no conclusion is claimed for its remaining assertions.
- Current SP drag gesture: **23/25 PASS**. `SPG-AIM-RETICLE-ON-ARROW-TARGET` fails for both preview modes. The arrow appears without a card face, but the target highlight/marker requirement is not satisfied.
- P4.3 GUI input capture: **13/16 PASS**; actual addon drag, legal-target drop, and keyboard-confirm-payment cases fail. Thus the complete input flow is not accepted.
- Visual comparison still shows overlap among active battlefield portraits and differences from the pinned target in command layout/frame styling. Final high-fidelity visual approval remains pending; do not label V2/V3 visual exit or V3.5 final review accepted.

Raw local logs and rendered PNGs for this run were kept outside the repository under `%TEMP%\arbitrium-qa-481cf8b-logs` and `%TEMP%\arbitrium-qa-481cf8b-evidence\outputs\p4_input_capture\v35_481cf8b`. These paths are execution evidence for this machine, not portable CI artifacts.

> **STATUS: TEST PLAN ONLY — ZERO NEW EXECUTION CLAIMS**（2026-10-15）。
> V0 文件契約對應：`BATTLE_UI_DESIGN_SYSTEM.md`、`BATTLE_UI_COMPONENT_CONTRACT.md`、`06_VISUAL_REFACTOR_OWNERSHIP_PLAN.md`。
> Baseline: `ui/hud-visual-refactor-20261015` originally from `master@5103e40a4b95da82f2561b29c2604e9514fd398b`。開始執行前重查 source HEAD/最新 master 和 WIP 差異；不得依舊 README 宣告新版遊戲規則。
> 測試值、視覺相似門檻為**工程驗收候選**，非 Gameplay/Balance canon。尚無新版 Godot 執行、截圖比對、人類操作驗證的紀錄；正式結果需填表附 timestamp/runtime/Git SHA/log/seed。

## 0. 證據層級與停工條件

| 層級 | 可以主張 | 不可以推論 |
|---|---|---|
| V0 Spec | Component、Design Tokens、視覺/互動測試已定義 | Godot UI 已達商業品質 |
| V1 Structural | 真 Scene/GDScript 已拆＋現有 GUI regression 成功 | 佈局已像概念圖 |
| V2 Layout | 1280/1920、多手牌狀態真的截圖和 bounds PASS | Theme/素材已完成 |
| V3 Visual | 參考稿逐區審查、有可回滾資源和 Theme | 使用者已核准最終商用美術 |
| V4 Interaction | Reaction/Casting/Combo/Last UI 的真實互動按規格驗證 | Domain 平衡數值已正式定案 |
| V5 Acceptance | 同 Commit 的 CI、互動測試、性能及人工畫面審查 | 真人 playtest（除非另有實測） |

**Hard stop**：來源 HEAD 不明、Domain 規格衝突、未驗證的 WIP 被當正式版、控制元件崩潰、既有測試 oracle 被弱化、UI 互動改掉 authoritative state/replay hash。尊重 QA Skill「同一 test group 首次＋兩次修復重測」限制；P4.4 第三輪 14/16（兩個 PNG save 失敗）**不因新 branch/檔案改名重置額度**。

## 1. Visual Reference pinning — 未完成之前禁止「高保真 VERIFIED」

先由 Codex/美術整合者取得**本對話使用者最後核准的手牌下沉畫面**真 PNG，放進 repo 核准位置或可存取的固定資產庫（禁止使用僅存在聊天中的不穩定連結作 CI source），紀錄：

```yaml
visual_target:
  id: UI-REF-S01
  status: PENDING_REPO_PIN
  approved_by: user (direction approved in chat; final PNG hash pending)
  file_path: TODO
  sha256: TODO
  resolution: TODO
  cropped_safe_area: TODO
  decision_notes:
    - lower bottom hand, no extra count bar
    - party portraits as actor switch
    - no deck/discard permanent info
    - no fixed turn-order HUD
  illustration_only: true  # NOT source of gameplay names/costs
```

其餘 `S02～S06` 的概念圖可做多張視覺參考，但**所有**展示文字、角色與 Boss 類型仍以現有資源和核准規格為準。比較時請使用相同視窗尺寸、同角色、同 Boss status 和同 action/state；若圖片沒有權威運行資料則只比較佈局/風格，不比較劇情/數字的逐像素。

## 2. 畫面接受矩陣（必拍真實 Godot 視窗，不接受 ImageGen 替代）

| Case ID | Screen / Fixture | 觀察點 | 最少證據 |
|---|---|---|---|
| UI-VIS-S01 | Player Idle：角色 A、4 張真手牌 | Party×3 可選、AP、Boss HP/Break/Intent、底部手牌、CommandMenu/Log | 1280 zh_TW & 1920 zh_TW PNG |
| UI-VIS-S02 | Player selected card | Selected 卡抬升，詳情/target/confirm 不遮擋，選中不扣費 | Before/After 1280 PNG + state hash |
| UI-VIS-S03 | Chantless vs Full | 顯示同卡模式/合法成本、Casting Stability vs Focus Ward、延遲 | 1280 zh_TW PNG + 真 preview |
| UI-VIS-S04 | Enemy Action + Reaction | RP、Intent、基本 Guard/Protect + 持有SP、手動 Queue/Reorder/Confirm/Pass | 1280 zh_TW PNG + click tape |
| UI-VIS-S05 | Combo opportunity | 正常出牌 vs Combo preview、合作兩角色、合法支付 | 1280 zh_TW PNG + Domain event IDs |
| UI-VIS-S06 | Last Spell confirm | Full-only、不可逆警示、成功 Exhausted、未釋放 HP0 強制失效 | 1280 zh_TW PNG + commands |
| UI-VIS-S07 | Boss Break / Exposed / status | HP/Break、CastingStability、Barrier/FocusWard 明確區隔 | 多狀態圖＋來源事件 |
| UI-VIS-S08 | Invalid card / Exhausted / Incapacitated | 不能行動、灰態仍可讀、tooltip 有原因，沒有誤確認 | screenshot + rejection hash |
| UI-VIS-S09 | Battle victory / defeat | Result overlay 不受老畫面殘留 UI 阻擋；結算來源 Domain | 兩種 PNG + outcome evidence |
| UI-VIS-S10 | 0／1／4／8 cards | 無虛構手牌數、1 卡置中、4 卡易辨、8 卡不越界可點 | 兩解析度 bounds report + PNG |
| UI-VIS-S11 | zh_TW ↔ en + restart HUD | 長字串不溢出、同一 action identity；切語後所有 signals 可用 | 1280+1920 × 2 languages |
| UI-VIS-S12 | Reaction modal input guard | modal focus 不穿透、按取消/Pass 行為正確、沒有強制 timer | pointer/keyboard input replay |

S03/S05/S06 如在當前 master fixture 尚無完整可互動路徑，標 `BLOCKED_FIXTURE` / `IMPLEMENTED_NOT_VERIFIED`，不可用假的 card/Domain event 當成正式通過；可另外產 `MOCK_ONLY` 截圖並**明確分開**。

## 3. Layout geometry / clip / overlap：可自動化的檢查

對每個 required visible/control 用 `get_global_transform()` 轉換四角後測視窗邊界，而非只看未旋轉的 `position+size`。必要時記錄 clip、scale、z-index、mouse_filter、Control visible/disabled、focus owner。

- **UI-LAYOUT-001**：1280×720（原生設計）、1920×1080（放大）切換，同一 CardInstance ID 的卡片無越界；8 張轉角四角均 `0≤x≤width` 且 `0≤y≤height`，容許 screenshot measurement ε=1px（候選，實際渲染舍入另註）。
- **UI-LAYOUT-002**：0/1/4/8 手時，沒有無故隱藏的 playable 卡或重疊不可點的 click target；8 張可用 mouse/keyboard 全數 focus；1 張置中在 HandView 可見範圍。
- **UI-LAYOUT-003**：未選中卡的視覺最底緣距 viewport bottom **8～20 design px 起始目標**；最終值依 target PNG 實測核准；任何卡不可有一角被裁。選中卡上移 12～28 design px（候選）＋可見選中輪廓，不遮住核心 Boss 目標。
- **UI-LAYOUT-004**：左 Party/Command 相互不交錯；Boss HP/Break 與 Intent 不卡住；Details/Log 不穿插覆蓋；modal 整體位於 viewport。若情境式浮層允許覆蓋 World，必須能關閉/Pass 且不擋必要動作。
- **UI-LAYOUT-005**：不出現冗餘 portrait switcher／牌庫/棄牌/手牌計數 HUD／固定行動順序列表。注意 Reaction **draft queue 不是**固定行動順序，不可誤刪。
- **UI-LAYOUT-006**：多行繁中與更長的英文 key、Error、技能說明可讀、沒有逐字垂直斷行或負空間溢出；若需長內容使用 ScrollContainer 且不會撐壞 UI。
- **UI-LAYOUT-007**：Pointer hit-region 與真 World actor/boss 目標一致；隱藏／非法 target button 不攔截滑鼠；Modal 期間底層 card 不能偷接收點擊。
- **UI-LAYOUT-008**：低動效模式 hover/focus/selection 仍有清楚非動畫提示，且不影響 Domain Event/Replay。

以上單一測試若需要改候選 threshold，必須留下真實 screenshot + 使用者批准紀錄，不能偷偷放寬成大數字讓測試綠燈。

## 4. Visual fidelity review（設計師人工審查＋量化輔助）

每個 `S01～S06` 拍相同渲染條件的真截圖，生成**左右並排**、透明 50% 疊圖、以及註記差異版三種比對。僅在可合理匹配時使用物件 bounding box 比較，不應將背景/卡圖的不同合法素材誤判為 UI layout 失敗。

**必審六個維度**，每項 0=嚴重不符合、1=略符合、2=結構正確但缺重要質感、3=視覺一致且可讀、4=高度接近核准參考且互動正確；未對照圖則留 `NOT_ASSESSED`：

| Dimension | 主要評估 |
|---|---|
| Spatial layout | 左/中/右權重、HUD 相對位置、戰場空間 |
| Hand presentation | 貼底弧形、選中提升、4/8 張仍可閱讀/點擊 |
| HUD visual language | 裝飾邊角、材質一致性、薄透面板、適度發光 |
| Typography + localization | 繁中主要文字/英文切換、字階與狀態標籤 |
| Information hierarchy | AP/RP、Intent、HP/MP/Break、選卡與可執行操作的焦點 |
| Interaction feedback | focus、hover、drag、disabled、Reaction draft、invalid reason |

**V2 Layout Exit**：Spatial layout / Hand presentation / Information hierarchy 各至少 3，且全部 `UI-LAYOUT` hard constraints PASS，其他維度可保留改善空間。

**V3 Visual Exit**：六維各至少 3，總分至少 20/24 為「提交使用者審查」**候選標準**，不是自動認定「使用者已核准」。Final Visual Acceptance 必須有使用者的明示確認；仍不可據此宣稱正式遊戲美術版權完整。

每輪提交以下差異表（不可只報平均分）：

```text
Reference ID/hash:
Code SHA/Godot version/renderer:
Viewport/locale/fixture seed:
Compared screenshots:
1) Most faithful 3 aspects (evidence)
2) Top 5 mismatches (node paths + measured bounds)
3) Suggested changes / ownership / regression risk
4) Which differences are accepted due to Domain/placeholder assets
5) Verdict: NEEDS_REVISION / READY_FOR_REVIEW / USER_APPROVED
```

## 5. 既有 runner / CI 對接（發現於 master 基線）

| 現有測試或證據 | 必須保留的行為 | V1 追加測試方向 |
|---|---|---|
| `tests/test_p4_scene.gd` | 真 BattleScene 可 instantiate | 新 component scene 可載入、父子 owner 正確 |
| `tests/test_p4_hud.gd` | P42 類：三角獨立4手、8手 bounds、換語系、Exhausted/失能不可出、Reaction 手動暫停 | 0/1/4/8、Theme update、alias API、狀態 labels |
| `tests/test_p4_input_capture.gd` | P43 類：真 mouse drag/drop、鍵盤切角+Confirm、Reaction 真 Pass click、1280/1920、rotated corners | Modal focus、失敗 drag return、翻譯後真 click、所有卡可 Focus |
| `tests/test_p4_integration.gd` | BattleController→M5 付款/傷害→VM→HUD/Director | 所有同 seed/commands event/final hash 相等 |
| `outputs/p4_3_idle_1280.png` 等 | 舊版工程真畫面 baseline | 每一 V stage 保存獨立 png；避免覆寫原始 `outputs` |
| `.github/workflows/` 對應 phase tests | 適用時用官方 Godot4.7.2 / true exit | 輸出可追溯到最新 commit，不以修過的假 log 當 PASS |

**已知風險**：`test_p4_input_capture.gd` 仍透過 `reaction_column.get_child(-1).get_child(-1)` 取得 Pass Button。V1 拆 Scene 前必須保留該路徑，或在獨立驗證改為明確的 semantic button getter 且仍**真實按鍵 click 測試**；不能改成直接發 Signal 來取代 UI。

P4.4 WIP 有額外測試／截圖寫檔問題；這份新 UI branch 的 GUI 測試不應被當成對 P4.4 已耗盡測試次數的規避。在沒有授權的情況下不另外重跑 P4.4 原 gate。新的獨立 UI case 可以依 QA Skill 的新測試群組規定執行，但必須清楚切分 scope，沒有任何重置先前失敗紀錄的描述。

## 6. Recommended capture/report payload（交付模板）

```yaml
repo: KuroNekoLi/arbitrium-nexus-godot
source_branch: ui/hud-visual-refactor-20261015
source_sha: <full 40-hex at test time>
target_visual_id: UI-REF-S01
target_visual_sha256: <required for high-fidelity claim>
godot_version: 4.7.2.stable.official.ed1daf0bf # verify from REAL executable
renderer: gl_compatibility
viewport: [1280, 720]
locale: zh_TW
fixture: <fixture file + seed + status>
screenshot: <real screenshot path + sha256>
test_name: <exact existing or new runner name>
test_ids: [UI-VIS-S01, UI-LAYOUT-001]
cases_executed: 0
cases_passed: 0
cases_failed: 0
cases_skipped: 0
exit_code: null
raw_log_path: null
review_result: NOT_EXECUTED
reviewer: null
```

不可保留模板內的 `0`／`null` 然後宣稱測過；每個結果都要從真實 CI / CLI 產生。

## 7. 每輪對使用者的交付內容

1. **Source diff**：Commit SHA、changed files、Scene Tree ownership before/after、尤其 HUD legacy APIs。
2. **Test**：real Godot 4.7.2 version、原始 stdout/stderr、exit code、seed、Domain replay/GUI suite/CI link 與 retry count。
3. **Visual**：同畫面參考與實跑 PNG（2 解析度、2 語言），加邊界/遮擋/中文字截斷分析與 mismatch 排名。
4. **Risk**：有哪些視覺稿造型仍是假素材、授權待確認；哪些交互與 Lv40/P4.4 尚未驗證。
5. **Next step**：只提出下個 V stage 小範圍，避免一口氣改掉全部 HUD。

**Gate**：V0 只需三份文件已在指定 UI 分支、內容可從 GitHub 直接讀取；不要求 Godot 測試，也絕不宣告 UI visually VERIFIED。V1 以上必須實際跑上述適用測試並留證據。
