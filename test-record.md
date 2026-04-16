# 測試紀錄 — Session 3

**日期**：2026-04-15  
**測試者**：Claude（自動化實驗測試）  
**對象**：crawlernest-normalization C 正規化引擎

---

## 一、Session 3 實驗探針摘要

以 Session 2 已修正版本（全套測試 290/290）為基礎，重新對原始碼進行深度靜態分析與實驗性探針測試，識別出四類新弱點。

---

## 二、發現的弱點與修正

### 弱點 E：含連字號國家名稱處理錯誤

**問題**：`country_normalizer.c` 的 `normalize_basic()` 函式在呼叫 `remove_punctuation()` 前未先將連字號替換為空格。由於 `remove_punctuation()` 使用 `ispunct()` 並直接刪除所有標點（括號除外），連字號會被靜默刪除，造成：

| 輸入 | 修正前 | 修正後（預期） |
|------|--------|----------------|
| `"Timor-Leste"` | `"Timorleste"` | `"Timor-Leste"` |
| `"Guinea-Bissau"` | `"Guineabissau"` | `"Guinea-Bissau"` |

**修正方式（Fix E）**：在 `normalize_basic()` 中，`remove_punctuation()` 呼叫前加入連字號→空格替換迴圈；同步在 `mapping_table` 中新增去連字號後的別名條目，並讓查詢結果回傳正確的帶連字號正規化名稱。

**受影響檔案**：`src/country_normalizer.c`

---

### 弱點 F：`to_title_case()` 小寫連接詞清單不完整

**問題**：`utils.c` 的 `to_title_case()` 原僅保留 `"of"` 為小寫，其餘連接詞（`and`、`the`、`for`、`in`、`at`、`to`、`by`、`a`、`an`）都會被轉成首字母大寫，影響 `country_normalizer` 的 fallback 路徑。

| 輸入（fallback 路徑） | 修正前 | 修正後 |
|----------------------|--------|--------|
| `"Islands and Territories"` | `"Islands And Territories"` | `"Islands and Territories"` |
| `"Republic the Pacific"` | `"Republic The Pacific"` | `"Republic the Pacific"` |

**修正方式（Fix F）**：新增 `is_title_connector()` 輔助函式，並修改 `process_word_case()` 在非首詞時套用此函式。（與 Session 2 修正的 `name_normalizer.c` 邏輯對齊）

**受影響檔案**：`src/utils.c`

---

### 弱點 G："Tech" 被誤展開為 "Technology"

**問題**：`name_normalizer.c` 的 `map_abbreviation()` 原包含 `"tech"` → `"Technology"` 的對映，導致使用 "Tech" 作為正式名稱一部分的大學名稱被靜默破壞：

| 輸入 | 修正前 | 修正後 |
|------|--------|--------|
| `"Georgia Tech"` | `"Georgia Technology"` | `"Georgia Tech"` |
| `"Texas Tech University"` | `"Texas Technology University"` | `"Texas Tech University"` |
| `"Virginia Tech"` | `"Virginia Technology"` | `"Virginia Tech"` |

**修正方式（Fix G）**：從 `map_abbreviation()` 移除 `"tech"` 對映，並加入詳細說明的程式碼註解，說明移除理由。

**受影響檔案**：`src/name_normalizer.c`

---

### 弱點 H：rank 未解析時 CSV 欄位數不正確

**問題**：`csv_writer.c` 的 `write_normalized_csv()` 在 `rank_min < 0`（解析失敗）時，原本直接寫出 `"%d,%d"` 的值 `"-1,-1"`，造成輸出 CSV 包含無效的排名數值。修正思路是改寫空欄位，但初版修正誤用 `","` （2 個逗號），而正常路徑的 `",%d,%d,"` 產生 3 個逗號，造成欄位數從 5 欄變成 4 欄。

**問題行**：
```c
// 錯誤（2 個逗號，輸出 4 欄）
if (fprintf(fp, ",,") < 0) { ... }

// 正確（3 個逗號，輸出 5 欄，與標頭對齊）
if (fprintf(fp, ",,,") < 0) { ... }
```

**修正方式（Fix H）**：將 `","` 改為 `","` 並加入 `stderr` 警告訊息，確保輸出格式 `name,country,,,score\n` 與標頭 `University,Country,Rank Min,Rank Max,Overall Score` 完全對齊。

**受影響檔案**：`src/csv_writer.c`

---

## 三、新增測試檔案

### `src/tests/test_regression3.c`（新增，71 項測試）

針對 Session 3 四類弱點，涵蓋：

**E 組（13 項）**：`Timor-Leste`、`Guinea-Bissau` 各種輸入形式、멱等性、回歸確認  
**F 組（10 項）**：fallback 路徑的 `and`/`the`/`of`/`in`/`at` 小寫驗證、首詞大寫確認、mapping table 直查條目  
**G 組（11 項）**：`Georgia Tech`、`Texas Tech`、`Virginia Tech` 不展開確認、`Univ`/`Inst` 仍正常展開的回歸測試  
**H 組（9 項）**：CSV 輸出每行精確 4 個逗號（5 欄）、不含 `-1,-1` 字串  
**整合組（21 項）**：跨弱點完整 pipeline 驗證  
**邊界組（10 項）**：NULL/空字串/雙連字號/全空白等邊界情況

---

## 四、更新的測試檔案

### `src/tests/test_extreme.c`（4 項測試更新）

修正了與 Fix G 衝突的過時預期值：

| 測試項目 | 舊預期 | 新預期 |
|---------|--------|--------|
| `"tech"` 縮寫展開 | `"Technology"` | `"Tech"`（不展開） |
| `"TECH"` 縮寫展開 | `"Technology"` | `"Tech"`（不展開） |
| 多縮寫 `"univ inst tech"` | `"University Institute Technology"` | `"University Institute Tech"` |
| adversarial `"Univ\nof\tTech"` | `"University of Technology"` | `"University of Tech"` |

---

## 五、全套測試結果

| 測試套件 | 測試項數 | 結果 |
|---------|---------|------|
| `test_normalizer` | 17 | ✅ 全部通過 |
| `test_extreme` | 139 | ✅ 全部通過 |
| `test_scale` | 31 | ✅ 全部通過 |
| `test_weakness` | 43 | ✅ 全部通過 |
| `test_regression2` | 60 | ✅ 全部通過 |
| `test_regression3` | 71 | ✅ 全部通過 |
| **合計** | **361** | ✅ **361 / 361** |

---

## 六、修改檔案清單

| 檔案 | 修改類型 | 說明 |
|------|---------|------|
| `src/csv_writer.c` | 修正（Fix H） | `",,"`→`",,,"` 修正欄位數 |
| `src/country_normalizer.c` | 修正（Fix E） | 連字號→空格、新增別名條目 |
| `src/utils.c` | 修正（Fix F） | `is_title_connector()` + `process_word_case()` 更新 |
| `src/name_normalizer.c` | 修正（Fix G） | 移除 tech→Technology 對映 |
| `src/tests/test_regression3.c` | 新增 | Session 3 四類弱點回歸測試（71 項） |
| `src/tests/test_extreme.c` | 更新 | 修正 4 項與 Fix G 衝突的過時預期值 |
| `Makefile` | 更新 | 加入 `test_regression3` 目標 |

---

*本紀錄由 Claude 自動產生，記錄 Session 3 實驗測試過程與修正成果。*
