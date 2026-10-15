# GDScript 開發規範

適用 Godot 4.x；API 以實際 binary 與對應官方文件確認。先讀 `SPEC_GUARDIAN.md`。

## 命名及格式

| 對象 | 慣例 |
|---|---|
| 檔案、資料夾 | snake_case |
| 變數、函式、signals | snake_case |
| 類別、節點名、enum 名稱 | PascalCase |
| 常數、enum 值 | CONSTANT_CASE |

使用 UTF-8、LF、tab 縮排；遵守既有 formatter 和 warning policy，避免把整個舊檔格式化造成無關 diff。官方行長建議作為可讀性指引，不把行數當成拆函式的理由。`SKILL.md` 及本套要求的大寫規範檔名屬文件命名例外。

## 型別與邊界

函式參數／回傳值、公開狀態、signal payload 明確型別。型別清楚時可用 `:=`；避免由 Variant 推斷出錯。JSON／Dictionary 等外部邊界先驗證 shape、型別、ID、版本，再進內部邏輯。現有 Domain 以 Dictionary snapshot 為契約，不為「全面 Resource 化」重寫它。

`as` 轉換不符合時可能得到 null；只有接受此語意時才用，並檢查結果。必要時先 `is` 再賦值。Object 型別可能為 null；已釋放 Node 參考使用適當的 `is_instance_valid()`，不要套用到純值。不要臆造 `Type?` 等 GDScript nullable 語法。依版本確認 typed collection 支援。不得關閉檢查或濫用 warning ignore 遮掩問題；必要局部例外附原因及測試。

## 函式、文件與錯誤

函式表達單一業務意圖，使用 early return 減少巢狀；共同規則集中於既有 resolver／policy。不要依賴大量隱藏 global state。避免純為行數而拆無意義 helper。

使用 `##` 為公開或易誤用 API 說明前置條件、狀態所有權、副作用、錯誤碼及生命週期。普通註解解釋規則來源、演算法、效能取捨或非直覺行為，不逐行翻譯程式碼。

Recoverable gameplay rejection 回傳具名 reason code 與不變狀態；programmer error 留下可定位 diagnostics。assert 只作開發期不變量檢查，不能取代 release 的輸入驗證。GDScript 不採 Python try/except。FileAccess／ResourceLoader／ResourceSaver 等檢查實際回傳或 error code，失敗不默默成功。重要失敗路徑必須可測。

## Resource、signals 與生命週期

CardData、CharacterData、EnemyData、StatusEffectData 若適合現況可為 Resource definition；與卡牌實例、HP、手牌、buff runtime 分離。UI 不修改共用定義。Resource cache／巢狀共享要列明所有權；`duplicate(true)` 不等於任何複雜圖皆完全隔離，需驗證子資源與版本行為。

場景依存由組合根注入 Node／Callable／設定；避免跨場景深層硬編碼路徑。`%UniqueName` 有場景 owner 範圍，不能當全域尋址。signal 表達發生的事件，不建立所有事件皆走全域 bus 的 spaghetti。

`_init()` 不依賴尚未進 tree 的兄弟節點；`_enter_tree()` 可重入，`_ready()` 不代表每次重入都重跑。連線需避免重複；長壽命 emitter 與捕獲物件的 lambda 明確管理 Callable／disconnect；不要宣稱所有 signal 都一定洩漏或一定自動安全。離場取消失效的 tween、await 回呼與視覺工作。只有需要全域生命週期的服務使用 Autoload；保留既有 addon 的 CG，勿另建萬用 GameManager。

## 審查／驗證

審查來源契約、權威狀態、型別／空值、資源共享、重入清理、錯誤原子性及現有測試。`--check-only --script` 是 parse Gate，不能證明 scene references、runtime 或 gameplay 正確。沒有實際 Godot 版本與執行紀錄就標 NOT_EXECUTED。

官方依據：[Style guide](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/gdscript_styleguide.html)、[Static typing](https://docs.godotengine.org/en/4.7/tutorials/scripting/gdscript/static_typing.html)、[Resources](https://docs.godotengine.org/en/4.7/tutorials/scripting/resources.html)、[Signals](https://docs.godotengine.org/en/4.7/getting_started/step_by_step/signals.html)。
