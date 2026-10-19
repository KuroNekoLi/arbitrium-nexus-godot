# BKC-01 — Break C 文件驗收／差異盤點（2026-10-20）

> **交付性質：DOCS_REVIEW_COMPLETE；NO_GAMEPLAY_CHANGE；NO_GODOT_TEST_RUN。**  
> 分支 `design/bkc-01-break-c-spec-20261020` 自最新已核對 `master@8e16c8f4e7205d256b230953fd9dda07087a90a1` 建立。  
> 正式方向：[ADR-BKC-01](../../combat/adr/ADR_BKC_01_BREAK_C_20261020.md)｜Boss 行為：[BKC-01 契約](../../combat/engineering/BKC_01_BOSS_BEHAVIOR_CONTRACT.md)。  
> 判定規則：文件完整、鏈結一致與無程式碼變動屬 **BKC-01 PASS**；下面 BKC-02～04 的實戰案例只寫成驗收需求，**NOT_EXECUTED**，不因列出測試就宣稱通過。

## 1. 規格溯源及影響範圍

| 項目 | master 舊行為／真實來源 | BKC-01 新方向 | 後續責任 |
|---|---|---|---|
| Break 產生 | `tactical_sp_resolver.gd` 以 `break_damage` 降 `break_gauge`，歸0設 `break_locked` 並建 `BreakTriggered` | 歸0 **另建立一次 Exposed**，仍不打斷 SP 中途多 Hit | BKC-02 |
| Exposed 來源 | `create_exposed` 由特定卡／姿態建立，受 `expires_round` 影響 | Break 共通來源＋可選 Boss 直接／姿態來源，**共用一份狀態** | BKC-02/03 |
| Boss 選招 | `boss_ai_policy.gd` 以固定 policy 擇一，`break_locked` 直接選 `fallback_skill_id` | 普通招式 CANCEL、重大招式 DOWNGRADE；按已公佈分支結算 | BKC-03 |
| Intent 時序 | `m5_domain_resolver.gd::_end_phase_m53()` 在 `END_PLAYER_PHASE` 提交 Boss Intent | 先預告可依據之下一招／合法 Break 分支，保留敵方時序公平 | BKC-03 |
| 敵方排程 | `enemy_action_scheduler.gd` 排序公開 Intent，非 AI | 保留 Scheduler 與每行動 Reaction/Resolve；無新的敵 AP 池 | BKC-03 |
| Casting | M4 詠唱獨立 stability/Focus Ward，普通法術合法 Interrupt | Break 不等於 Disruption，需阻止同一施法被取消兩次 | BKC-03 |
| Combo | 蓮 R01/R07 命中可 Setup，無需 CORE_OPEN；第二人真卡真付費 | Exposed 是另一狀態，不能白送 Combo | BKC-02/04 |
| Boss 內容 | Lv40 以 B01～B11、CORE_OPEN、Break fallback 為候選 | B01～B11 類別／fallback 尚需逐招核准；可以有零自主 Exposed Boss | BKC-03 |
| HUD | 顯示 HP/Break/Intent/Exposed/Casting 訊息的成熟度待驗收 | 用事件投影正常／取消／降級，詠唱時才顯示穩定度 | BKC-04 |
| 生命週期 | Last Spell 成功真正退場，HP0失能仍留場 | 不改、不提供復活或免費付費 | 全部回歸 |

## 2. 後續測試清單（設計驗收案例，不是實測結果）

| Case | Given / When | Then | Owner / 狀態 |
|---|---|---|---|
| `BKC-T01` | BreakGauge 剩5、合法 R01 造成6 BreakDamage | SP 所有 Hit 先結算，再觸發一次 Break＋至多一份 Exposed | BKC-02／NOT_EXECUTED |
| `BKC-T02` | 普通招式已預告 CANCEL、尚未開始 | Break 後本次敵行動無攻擊、無假 Reaction，階段續行 | BKC-03／NOT_EXECUTED |
| `BKC-T03` | 重大招式帶合法 fallback | 玩家事先看到降級資訊，失衡後按公佈目標／時機執行 | BKC-03／NOT_EXECUTED |
| `BKC-T04` | 多 Hit SP 第1 hit 即削至0 | 其後 Hit 不被截斷、Break只觸發一次 | BKC-02／NOT_EXECUTED |
| `BKC-T05` | Boss 無 ON_BOSS_ACTION/ON_POSTURE_AND_SP | Profile 合法，玩家仍能透過 Break 建 Exposed | BKC-02/03／NOT_EXECUTED |
| `BKC-T06` | Boss 已被 Break 鎖定再次受 BreakDamage | 不重複鎖行動、不增加第二份 Exposed | BKC-02／NOT_EXECUTED |
| `BKC-T07` | Boss 成功執行標記自曝的招式 | 產生一次 Exposed；若該招 CANCEL 不產生 | BKC-03／NOT_EXECUTED |
| `BKC-T08` | CORE_OPEN 且指定 SP 合法命中 | 姿態型 Exposed 可建立；CORE_OPEN 單獨不會自動建立 | BKC-02/03／NOT_EXECUTED |
| `BKC-T09` | 同一技能建立新 Exposed 同時有造成 HP 傷害 | 不會自建自用；後續合格 SP 才利用 | BKC-02／NOT_EXECUTED |
| `BKC-T10` | 下一次 SP 利用 Exposed，多 Hit／全 Miss | 至多消耗一次；全 Miss 依核准成功政策不消耗 | BKC-02／NOT_EXECUTED |
| `BKC-T11` | 本 PlayerPhase 最後 AP 打出 Break | Exposed 仍留至至少下一玩家階段結束（**候選期限**） | BKC-02／NOT_EXECUTED |
| `BKC-T12` | Boss 已有 Exposed，之後另有 Break／自曝事件 | 不無限疊加／刷新；Break 行動壓制仍成立 | BKC-02／NOT_EXECUTED |
| `BKC-T13` | 蓮 R01/R07 命中，CORE_OPEN 關閉 | ComboOpportunity 可成立；非 Break／非 Exposed 自動條件 | BKC-02／NOT_EXECUTED |
| `BKC-T14` | Casting Interrupt 與 Break 同時指向同一法術 | 只取消／降級一次，不偷轉第二招；Casting Stability 與 Gauge 分別記錄 | BKC-03／NOT_EXECUTED |
| `BKC-T15` | 麻痺／冰凍與 Break 同 Action | 只壓制一次，Boss 個別控制抗性／保護窗另按 ADR | BKC-03／NOT_EXECUTED |
| `BKC-T16` | 一次 Break 後下一玩家階段企圖再次 Break | 按已核准恢復／保護期處理（**候選**） | BKC-02/03／NOT_EXECUTED |
| `BKC-T17` | B05/B08 蓄力遭 Break | 不偷換未預告的 B11 單體攻擊 | BKC-03／NOT_EXECUTED |
| `BKC-T18` | 已公告 Intent 正式開始或終局 | 不 retroactive 取消；勝敗與 Last Spell 規則不變 | BKC-03／NOT_EXECUTED |
| `BKC-T19` | 玩家有合法 Reaction 且 Boss DOWNGRADE | 不自動 Pass、不倒數，反應窗口保持正確 | BKC-03/04／NOT_EXECUTED |
| `BKC-T20` | 固定 seed／Legacy Replay 載入 | 新版本回放穩定、舊配置保留歷史語義與 hash | BKC-02/03／NOT_EXECUTED |
| `BKC-T21` | 1280×720 和 1920×1080、繁中與英文 | 正常／取消／降級、Exposed與Casting 有清楚投影 | BKC-04／NOT_EXECUTED |

## 3. BKC-01 文件驗收門檻

- [x] 由 `master` 建立**新獨立分支**，不更動其它 Repository；HEAD 以工具重新核對。
- [x] ADR 明確區分「**方案 C 使用者已核准**」與「具體成本／期限／資料結構待核准」。
- [x] 契約允許 Boss 完全**不自主露弱點**，並保留直接與姿態型兩類可選來源。
- [x] Break、Exposed、ComboOpportunity、Casting Disruption、Weakness 五種機制沒有混為一種。
- [x] 對齊 R01/R07 在 CORE_OPEN 關閉時仍能建 ComboOpportunity。
- [x] 現有 AI 在 END_PLAYER_PHASE 才選招的差異已明示，未聲稱意圖預告已實作。
- [x] B01～B11 有待審分類清單，注明 fallback 不是可隨意套用 B11。
- [x] 文件路徑／新 ADR／Boss 契約互相連結，已有工程查核及後續測試清單。
- [x] 無 Gameplay code 更改：BKC-01 對程式碼的 diff 必須為零。
- [ ] 本輪已通過 Godot／UI／實機：**不適用且未執行**，不能勾選。

## 4. BKC-02 前的決策 Gate

即使 BKC-01 DOCS 完成，仍**不可擅自定數值**：

1. Exposed 加成公式、合法利用的 SP 範圍、期限與時序；
2. BreakGauge 回滿／恢復保護期長度，是否允許在保護期先累積 Gauge；
3. Break 與 Casting Interrupt／Hard-CC 同時觸發時的固定優先序；
4. Boss 的技能 BreakResponse / fallback、其公開 Intent 何時鎖定；
5. 版本化舊 Fixture/Replay 的遷移路徑。

建議工程切分：**BKC-02 Tactical Domain（Break→Exposed） → BKC-03 BossAI／Intent／Casting → BKC-04 HUD／QA**。重大差異先取得核准再轉正式現行規格；完整實際驗證結果需後續寫入新報告，不能回填為 BKC-01 已通過。
