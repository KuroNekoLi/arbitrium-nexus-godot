# 敵人與 Boss 圖鑑｜秘紋守衛・零式

> **Boss的意圖公開、Break與Casting Stability分離、React無倒數為已確認機制；本頁所有Boss姓名、HP、技能、階段與平衡數字是Lv40測試內容候選。** 目前只有下列1名已有完整設計的 Boss；不能捏造其他正式怪物。

## 秘紋守衛・零式（Arcane Sentry Type-0）
- `EnemyID=TEST_BOSS_ARCANE_SENTRY`；三名Lv40角色對1名Boss的演示戰。
- 早期設計 **HP3000／BreakGauge30**；現行 Godot `lv40_content.gd` 候選已改為 **HP2700／BreakGauge22**。兩套版本的血量、階段閾值、攻擊力**不可任意混用**。
- 目前配置的其他候選：PAtk417、MAtk434、PDef90、MDef85、Accuracy105、Evasion90。
- 這一敵人的元素抗性候選：FIRE系HP傷害×1.15、ARCANE×0.90、NEUTRAL×1.00；不等於全遊戲通用元素規則。

## 招式圖鑑（內容設計 B01～B11）
| ID | 招式 | 攻擊類型／範圍 | 玩家應對及效果 |
|---|---|---|---|
| B01 | 鐵拳突襲 | 物理×1.35，單體 | 可Protect與Guard |
| B02 | 雙刃連擊 | 物理×0.80，2hit／同一EnemyAction | 同一合法反應窗口內 Guard／Protect 可涵蓋適用兩hit |
| B03 | 弧光穿刺 | 魔法×1.35，單體 | 命中後可附施法干擾；符合標籤的 on-hit 干擾跟隨實際受擊者 |
| B04 | 共振脈衝 | 魔法×1.05，友方全體 | 不可基本Protect全體，可各自依法Guard |
| B05 | 核心預熱 | 0傷，開始Boss蓄力 | 建施法實例、告知下一次強光束及CORE_OPEN |
| B06 | 超載光束 | 魔法×2.35，預告單體 | 已開始的Boss施法未被打斷才會釋放；可Protect |
| B07 | 重構護壁 | Boss自己 | 獲得180候選HP Barrier，不免費附普攻 |
| B08 | 終末蓄能 | 0傷，開始高階蓄力 | 下個合法時點才可能釋放全體法術 |
| B09 | 終末掃射 | 魔法×1.50，全體 | 不可基本Protect；可Guard、護盾或合法干擾 |
| B10 | 冷卻校正 | 0傷，Boss自己 | 蓄力被合法打斷後冷卻，不偷換免費攻擊 |
| B11 | 失衡降級攻勢 | 物理×0.60，單體 | Break使**下一次合格且尚未開始**的Boss行動弱化 |

## 公開意圖與3種戰況
Boss發布 `EnemyIntent`：技能、目標／範圍、預期時點、可否Protect、是否命中型或直接干擾、已明示條件分支。公開後不可偷偷換招或重選鎖定目標。單次蓄力就是一次EnemyAction，不可同輪又免費普攻。候選戰況為初期守衛→中期過載與護壁→低血量終末蓄力；**設計 v0.1 65%/30% 血量閾值來自HP3000版本**，採HP2700的程式應按當前Boss規則和測試核對，不可直接套舊1950／900邊界。

蓮 R01/R07 只有在這個Boss的 `CORE_OPEN` 等合法 `exposed_trigger_profiles` 姿態才有機會建立Exposed；Analyze不會免費建立破綻。Boss Break Gauge與某次施法Casting Stability是不同條，不可把 A05的8 Disruption當成8 Break。

## 功能驗證範圍
已存在 `scenes/battle/lv40_playable_battle.tscn` 的可載入正向Scene，`tests/test_p4_lv40_playable.gd` 有32項正向測試、相關CI有紀錄；這**只驗證限定Scene/Domain接線**。所有11招內容精度、完整人手操作、最終視覺、每種平衡策略與Lv40真正可玩通關依然須另行測試，不可因Scene存在就升級 `BALANCE_ACCEPTED`。

## BKC-01：下一版 Boss 破綻模式（資料設計，尚未實裝）

玩家透過 Break 製造 Exposed 的路徑將成為 Break C 共通能力；**Boss 不必自主暴露弱點**。Boss Profile 可另外配置：（1）零自主來源；（2）成功施放特定招式後直接露破綻；（3）開啟 `CORE_OPEN` 等姿態，再由指定 SP 觸發 Exposed。三者最後共用一份 Exposed 狀態，不建立第二種「Boss 破綻 Debuff」。

完整資料契約、現有 B01～B11 的 **REGULAR/CANCEL 或 MAJOR/DOWNGRADE 候選分類**與尚待核准的 fallback 見 [BKC-01 Boss 行為契約](engineering/BKC_01_BOSS_BEHAVIOR_CONTRACT.md)。**這張 Boss 圖鑑前面的 B01～B11 效果依然是現行候選內容**；BKC-01 不更動 HP2700／Break22／元素倍率等既有 fixture，也不宣稱已調整 AI 或提前公布 Intent。
