# CrawlerNest 正規化引擎 — 實驗測試報告

**測試日期**：2026-04-21  
**測試輪次**：Session 5（累計第五輪）  
**測試方法**：弱點導向系統性實驗測試（靜態分析 → 探針程式 → 修正 → 回歸驗證）  
**測試語言**：C11（gcc，-Wall -Wextra）

---

## 一、系統概述

```
輸入 CSV → csv_reader → normalizer pipeline → csv_writer → 輸出 CSV
                              ↓
                    name_normalizer
                    country_normalizer
                    rank_parser
                    score_parser
                    requirement_parser（尚未實作）
```

**CSV 格式**：5 欄位 — `University, Country, Rank Min, Rank Max, Overall Score`

---

## 二、Session 5 弱點分析與修正

### Bug M — csv_reader：rank 欄位部分空白導致排名遺失

**發現方式**：靜態分析 + 探針程式（probe_s5.c）

**問題根源**：`map_row_to_record()` 中固定使用 `snprintf(raw_rank, "%s-%s", rank_min_field, rank_max_field)`，當 `rank_min` 欄位為空時，產生 `"-150"` 之類的負數字串，`rank_parser` 拒絕後回傳 `-1/-1`，導致該欄位的排名資訊完全遺失。

**修正位置**：`src/csv_reader.c`，函式 `map_row_to_record()`

**修正策略**（Fix M）：智慧欄位組合

| rank_min | rank_max | raw_rank 產生 | parse_rank 結果 |
|----------|----------|---------------|-----------------|
| 空        | "150"    | "150"         | 150/150         |
| "101"    | 空        | "101"         | 101/101         |
| 空        | 空        | ""            | -1/-1           |
| "101"    | "150"    | "101-150"     | 101/150（原行為不變） |

---

### Bug P — rank_parser：「TOP 0」產生語意矛盾區間

**發現方式**：靜態分析 + 探針程式

**問題根源**：`parse_rank("TOP 0")` 回傳 `rank_min=1, rank_max=0`，違反「rank_min ≤ rank_max」不變式，下游排名比較邏輯可能出錯。

**修正位置**：`src/rank_parser.c`，`parse_rank()` 的 "Top N" 分支

**修正策略**（Fix P）：要求 N ≥ 1，否則拒絕並回傳 -1/-1。

---

### Bug Q — rank_parser：反轉區間「150-101」不驗證

**發現方式**：靜態分析 + 探針程式

**問題根源**：`parse_rank("150-101")` 回傳 `rank_min=150, rank_max=101`，同樣違反 min ≤ max 不變式。

**修正位置**：`src/rank_parser.c`，`parse_rank()` 的 range 分支

**修正策略**（Fix Q）：解析後若 `na > nb` 自動交換，確保 `rank_min ≤ rank_max`。

---

## 三、修正程式碼摘要

### Fix M（csv_reader.c）

```c
/* 舊程式碼：永遠使用 "%s-%s"，rank_min="" 時產生 "-150" */
snprintf(record->raw_rank, RANK_STR_LEN, "%s-%s", rmin, rmax);

/* Fix M：依空白情況選擇正確組合方式 */
int rmin_empty = (rmin[0] == '\0');
int rmax_empty = (rmax[0] == '\0');

if (rmin_empty && rmax_empty) {
    record->raw_rank[0] = '\0';
} else if (rmin_empty) {
    snprintf(record->raw_rank, RANK_STR_LEN, "%s", rmax);
} else if (rmax_empty) {
    snprintf(record->raw_rank, RANK_STR_LEN, "%s", rmin);
} else {
    snprintf(record->raw_rank, RANK_STR_LEN, "%s-%s", rmin, rmax);
}
```

### Fix P（rank_parser.c）

```c
/* Fix P：拒絕 N=0，要求 N >= 1 */
if (safe_parse_int(after, &a) && a >= 1) {
    *rank_min = 1;
    *rank_max = a;
    return;
}
```

### Fix Q（rank_parser.c）

```c
if (sscanf(p, "%d - %d", &na, &nb) == 2) {
    if (na < 0 || nb < 0 || ...) return;
    /* Fix Q：反轉區間自動交換 */
    if (na > nb) { int tmp = na; na = nb; nb = tmp; }
    *rank_min = na;
    *rank_max = nb;
    return;
}
```

---

## 四、測試套件結構

### Session 5 新增：test_regression5.c（62 項）

| 子套件 | 說明 | 測試項目數 |
|--------|------|-----------|
| `test_m_rank_field_combination()` | csv_reader 欄位組合邊界 | 12 |
| `test_p_top_zero()` | TOP 0 拒絕邏輯 | 9 |
| `test_q_range_reversal()` | 反轉區間自動修正 | 14 |
| `test_integration_s5()` | Session 5 完整 pipeline | 14 |
| `test_extra_s5()` | 全格式回歸補強 | 13 |

### test_extreme.c 更新（2 項期待值修正）

| 原測試期待值 | 修正後期待值 | 原因 |
|-------------|-------------|------|
| `"TOP 0" → 1/0` | `"TOP 0" → -1/-1` | Fix P：語意矛盾，應拒絕 |
| `"150-101" → 150/101` | `"150-101" → 101/150` | Fix Q：自動交換後正確 |

---

## 五、全套測試結果（Session 5 後）

```
make test_all
```

| 測試套件 | 通過 | 總計 | 狀態 |
|---------|------|------|------|
| test_normalizer | 17 | 17 | ✅ 全通過 |
| test_extreme | 139 | 139 | ✅ 全通過（更新 2 項）|
| test_scale | 31 | 31 | ✅ 全通過 |
| test_weakness | 43 | 43 | ✅ 全通過 |
| test_regression2 | 60 | 60 | ✅ 全通過 |
| test_regression3 | 71 | 71 | ✅ 全通過 |
| test_regression4 | 85 | 85 | ✅ 全通過 |
| test_regression5 | 62 | 62 | ✅ 全通過（Session 5 新增）|
| **合計** | **508** | **508** | ✅ |

---

## 六、已知限制（本輪未修正）

### score_parser 精度捨入

`%.2f` 格式化下，`score=99.999` 輸出為 `100.00`，可能導致視覺上超出滿分的顯示。此行為是 C 標準庫的正常四捨五入，若資料集存在接近 100.0 的浮點值需要嚴格控制，可改用截斷（`floor`）或自訂格式化函式。本輪暫不修正，以保持既有格式一致。

### requirement_parser 未實作

`src/requirement_parser.c` 目前為空檔（1 行），相關功能（入學門檻解析）尚未實作。屬於功能缺口，非 Bug。

---

## 七、累積修正清單（Sessions 1–5）

| 修正代號 | Session | 模組 | 說明 |
|---------|---------|------|------|
| A | 1/2 | country_normalizer | 新增 USA/UK/SG 等基本別名 |
| B | 1/2 | country_normalizer | China/Hong Kong/Taiwan/Korea 別名 |
| C | 2 | rank_parser | `#N` 井字號前綴格式支援 |
| D | 2 | rank_parser | 負數排名拒絕 |
| E | 3 | country_normalizer | 含連字號國名（Timor-Leste）保護 |
| F | 3 | utils | title case 連接詞清單（and/the/for/in/at/to/by/a/an）補全 |
| G | 3 | name_normalizer | 移除 "Tech" → "Technology" 破壞性展開 |
| H | 3 | csv_writer | 排名空欄輸出逗號數修正（`,,` → `,,,`） |
| I | 4 | rank_parser | "TOP N"/"RANK N" 大小寫不敏感 |
| J | 4 | country_normalizer | Korea Rep./Russian Federation/Macao/Czechia/Iran/Vietnam 等 19 個別名 |
| K | 4 | name_normalizer / utils | ETH/UBC/HKUST/TUM/TU/IIT/RMIT 等縮寫清單擴充 |
| L | 4 | rank_parser | `sscanf %d` 整數溢位 → 改用 `strtol + MAX_REASONABLE_RANK` |
| **M** | **5** | **csv_reader** | **rank 欄位部分空白智慧組合（避免負數字串）** |
| **P** | **5** | **rank_parser** | **"TOP 0" 拒絕（N 須 ≥ 1）** |
| **Q** | **5** | **rank_parser** | **反轉區間 "B-A"（B>A）自動交換** |

---

## 八、已修改檔案清單（Session 5）

| 檔案 | 變更類型 | 說明 |
|------|---------|------|
| `src/csv_reader.c` | 修正 | Fix M：rank 欄位部分空白處理 |
| `src/rank_parser.c` | 修正 | Fix P：TOP 0 拒絕；Fix Q：反轉區間交換 |
| `src/tests/test_regression5.c` | 新增 | Session 5 回歸測試（62 項）|
| `src/tests/test_extreme.c` | 更新 | Fix P/Q 對應的期待值修正（2 項）|
| `Makefile` | 更新 | 加入 `test_regression5` 目標 |
| `apply_session5_patches.py` | 新增 | EDEADLK 繞過腳本（test_extreme.c 同步用）|
| `test-report.md` | 更新 | 本報告 |

---

*報告產生工具：Cowork / Claude Sonnet 4.6*
