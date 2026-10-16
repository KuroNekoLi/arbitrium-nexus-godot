# Last Spell Target Scope — USER_APPROVED UI Decision

來源：2026-10-16 使用者「使用終極法術的邏輯」及三張原始參考圖。取代 V35 SPG-07 中隱藏戰場三人的預覽；啟動前仍明確確認，啟動後不可取消。

| ID | 核准行為 | 實作 |
|---|---|---|
| LST-UI01 | 從技能資料判斷敵我／單全 | ContentConfig → LastSpellReadModel → Preview |
| LST-UI02 | 敵單唯一目標自動帶入；多敵可切換與記憶 | 目標卡／戰場標記，選取不付款 |
| LST-UI03 | 敵全標註所有有效敵人 | 全體選定，啟動一次，Domain 分別結算 |
| LST-UI04 | 友方依自身範圍呈現合法隊友 | 紬目前是我方全體，不因圖示改成新單體技能 |
| LST-UI05 | 大型肖像、下方框、費用／時程、目標卡、啟動／取消 | 既有 Portrait / NinePatch / i18n；無固定行動順序 |
| LST-DOM01 | 全體標示必須有真正全體效果 | 修補文件 25 朱音敵全在 Godot 原只打 Boss 的落差 |
| LST-COMPAT01 | 舊 Replay 不被新內容重新解釋 | 新 provisional-2；舊 provisional-1 保留歷史單 Boss 行為 |

單體目標點選只負責選定，終極法術一律按獨立「啟動」鍵提交。普通攻擊再次點擊直接出手，不適用於不可逆終極法術。

目前內容：蓮＝敵單；朱音＝敵全；紬＝我方全體。成本與期限仍從現有配置／Last.inspect 取得，全部 BALANCE_PROVISIONAL；沒有新增我方單體終極法術。

全體在釋放時取得仍存活的同陣營對象，延續我方群療既有方式。單一 anchor id 是 Command 相容欄位；新版本全體不因非施法者 anchor 死亡而整體失效。施法者釋放前 HP0 仍失效。

## Reference pinning

原檔在使用者 Downloads，已讀取像素；只作比較，沒有裁切成遊戲資產。

| Original file | SHA-256 |
|---|---|
| ChatGPT 圖像 2026年10月16日 上午08_15_04.png | daeb288087de33c1c53af8d1c10b2d7f059640689949976bc6238dfe93e9bde8 |
| ChatGPT 圖像 2026年10月16日 上午08_14_37.png | b09e947e1b755e1bdc9491c9edaa3bf2efa92173796bffb4ba9a629b69910bf7 |
| ChatGPT 圖像 2026年10月16日 上午08_14_57.png | 0b14621feacc4241013ec2af3cafb09ed40d3e6cd30f534d85d00ef5d9afd135 |

收據：[Engineering Note](../verification/ui/LAST_SPELL_TARGET_SCOPE_ENGINEERING_NOTE_20261016.md)。
