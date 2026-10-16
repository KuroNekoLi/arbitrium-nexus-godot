# 未合併分支 Code Review 與整合紀錄

日期：2026-10-16（Asia/Taipei）。Base：`50bf7b19b2f9c3d66c1a8cd267bd20ef7f56b4cd`。

本次使用者明確要求「code review 所有還沒 merge 的分支，最後 merge 到 master」，並再次選擇「維持暫緩，記錄驗證缺口」。因此授權整合與修正，不授權重跑 Combo Domain／滑鼠 GUI；不把合併視為驗收完成。新視覺維持 placeholder，等待使用者委託其他 AI 的素材。

## 分支範圍與處置

盤點包含本機 `refs/heads` 和 `origin` 遠端分支；逐一記錄 SHA／相對 base 的提交數及 source 檔案差異。資料見 `BRANCH_INVENTORY.json`、`SOURCE_AUDIT.json`。本機較舊 handoff tip 也納入；未提交工作目錄和其他工作區 detached HEAD 不屬本次分支合併，不搬動、不刪除。

| 分支群組 | 審查與整合處置 |
|---|---|
| `feature/combo-preparation-v2` | 合併 `b38f87e`；保留隔離複合命令、原始失敗證據與 deferred acceptance；沒有重跑其測試群組 |
| `poc/card-targeting-arrow-20261016` | 合併 `9f73140`；與 Combo 已重用的箭頭接線衝突時保留較完整的 Combo 整合，新增原箭頭測試／文件／workflow |
| `feature/spell-projectile-visuals-20261016` | 合併 `eb68b70`；人工整合 Director／Effects 衝突，保留 A→B 合作 cut-in、stationary casting、投射物與立即 skip cleanup |
| `ui/character-state-cg-20261016` | 合併 `cead45a`；三份 state atlas 為可替換候選 placeholder，補 manifest，來源／最終美術權仍待確認，不宣稱 Canon |
| `handoff/p4-lv40-chat-20261015` | M3/M4/M5、卡區及 Lv40 邏輯已有先前選擇性 promotion；比對目前程式保留新 roster、eligibility、retirement、Last Spell target scope，舊 pending patch 只作歷史 |
| `handoff/p4-card-localization-chat-20261015` | loader、雙語資源與卡圖 metadata 已納入 master；不覆寫目前 key 修正及新增翻譯 |
| `handoff/p4-readmodel-chat-20261015` | CommandFactory／ReadModel 已納入；保留目前 sanitized command 及 detachable snapshot，不恢復早期只接 fixture 的 UI |
| `handoff/p4-balance-research-chat-20261015` | policy／統計工具已存在，保留新版；舊 `test_lv40_balance.gd` 及其未執行研究 gate 保存為歷史 source，不讓內容候選改成正式平衡 |
| `handoff/p4-performance-qa-chat-20261015` | profile metric helper 已存在，保留 integer overflow 等後續修正；沒有宣稱 GUI GPU benchmark 通過 |
| `handoff/p4-encounter-ui-chat-20261015` | 舊 staging scene／capture 不代表現在 playable entry；保留現行 `lv40_playable_battle.tscn`，不以舊 fail-closed shell 覆蓋 |
| `handoff/p4-dispatch-index-20261015` | dispatch 任務文件為歷史，提交歷史保存，不新增執行路徑 |
| `integration/p4-reviewed-20261015` | 包含上述早期整合與回報；目前 master 已在 `c2796e31`、`d4d5b998`、`f40686cd` 選擇性 promotion。逐檔比對核心差異，保留後續已核准修正 |
| `ui/hud-visual-refactor-20261015` | component extraction／設計文件已在 master 並多次迭代；保留現行 HUD facade／modal isolation／手牌 |
| `phase3/m5-3-boss-break-exposed-combo` | Break／Exposed／真兩人付費 Combo 已被現行引擎吸收；不覆寫新版目標／retirement guard |
| `phase3/m5-4-outcome-core01` | 保留現行勝利優先與已核准真正退場；舊 all-exhausted pending 判定只保留舊 replay 語義 |
| `phase3/m5-5-full-battle-replay` | 真 command tape／100 seeds 原實作已存在；保留新 CI Fast／Integration／Full 分工，不覆寫舊大型 workflow |

上述較舊分支採 **history-only merge (`-s ours`)**，不是重新套用舊 tree：在 `b81702b` 合併前後 tree SHA 完全相同。舊來源完整保留在 merge parents；四個未採用的早期 source 另存 `historical-source/*.txt` 供審查，沒有把它們放回可執行測試路徑。此次請求取代舊文件的「不要整分支合併」操作限制，但沒有取代現行玩法或未核准規則。

| 衝突 | 舊分支方案 | 本次採用 |
|---|---|---|
| actor identity | A/B/C 綁定 stats／被動／Boss 優先角色 | roster／character／eligibility 內容驅動，維持目前 master |
| 終式退場 | 耗竭仍 targetable；全耗竭未決 | 已核准真正退場、敵存活且無在場者敗北；舊 tape 配置相容 |
| UI entry | staging／fixture-only shell | 正式 Lv40 playable entry；保留 fixture 測試用途 |
| CI | 舊分支大型全部跑與舊 smoke 相容殼 | 現行分工與已退役項目清理；不恢復八卡 runtime |

## 審查發現與修正

| ID／優先級 | 觸發與影響 | 修正與驗證 |
|---|---|---|
| BR-01 / P1 | Combo 拆成兩個演出 job 時只留下 actor，遺失卡牌 style 與各自 target；魔法可被畫成近戰、防護指錯目標 | `_on_resolved` 只在 visual command 補 metadata，Director 保留每個角色的 card／target；presentation fixture 驗證，不寫入 Domain tape |
| BR-02 / P1 | 正式 `CastingReleased` 沒有 `spell_id`；新 catalog 用合成測試事件時可過，但真 Full Chant 釋放沒有正確投射物 style | `annotate_releases` 從前一份 casting snapshot 補純顯示資料；原 authoritative event 不變；驗證 production-shaped 缺欄位事件 |
| BR-03 / P2 | 同一 scheduler receipt 含多個 release，使用最後一人的 style／caster 畫全部效果 | 依 release boundary 分組，各自選 style；兩人不同法術 fixture 驗證 |
| BR-04 / P2 | state CG 顯示時，施法 tint 仍改 hidden body；hit 與 skip tween 互搶或殘留 | 對可見 drawable 統一 tint tween；reset／狀態改變／離場 kill tween；驗證 visible CG flash 與 reset |
| BR-05 / P2 | static CG 隱藏攻擊動畫；前一段 lunge 未完時接下一段，return 起點可能偏離 home | 攻擊期間切回既有 frame animation，完畢恢復 CG；新攻擊以 home 為起點；兩段連續攻擊 fixture 驗證 |
| BR-06 / P2 | 新增三份 state atlas 沒有 asset manifest，易被誤當正式美術採用 | 補 SHA256／原分支 commit／PROVENANCE_PENDING／REUSED_PLACEHOLDER；未下載或生成新圖，待其他 AI 正式素材 |
| BR-07 / P1 | 機械合併早期 P4/M5 會恢復退休角色受擊／固定人物槽位／舊 UI workflow | 保留現行核准 tree，history-only merge 保存來源；merge tree 不變及 ancestry 檢查 |

## 本輪驗證與未執行

Godot `4.7.2.stable.official.ed1daf0bf`。最終程式修正 commit `a5e007e`；歷史吸收 commit `b81702b` 的 runtime tree 未改。最終四組測試均於此程式版本執行：

- `BRANCH_PRESENTATION_REPORT`：15/15，純 presentation fixture，沒有 gameplay submit／滑鼠事件。
- `SPELL_VISUAL_REPORT`：46/46。
- `STATE_CG_REPORT`：39/39。
- `TARGET_ARROW_REPORT`：26/26。
- 合計126；strict Godot log gate：0 errors。兩次 fresh import 無錯誤。
- CI 工具 unit tests：41/41。第一輪 Windows cp950 導致2項 decode error；設 `PYTHONUTF8=1` 後第二輪通過，沒有弱化 assertion。
- **未執行**：Combo Domain／GUI 第四輪、其他真人輸入／完整 Boss 戰、全體連攜、多搭檔／多 Recipe、新畫面 golden image 核准、GPU／平衡研究。原本 Domain136/142、GUI258/260 是保留紀錄，不能改成 PASS。

所有 raw logs 及 source SHA 固定於本目錄。新增 `ci-reviewed-presentation.yml` 僅執行上述126項 presentation；不包含暫緩的 Combo 測試。遠端 CI／master 更新狀態見 `MERGE_RECEIPT.md`。未刪除任何來源分支，沒有 force push，也沒有替其他工作區提交未完成內容。
