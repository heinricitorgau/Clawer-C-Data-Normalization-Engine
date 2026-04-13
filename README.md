# crawlernest-normalization

大學排名資料的正規化引擎，用於將爬蟲產出的 CSV 標準化為統一的大學名稱、國家名稱與數值分數格式。

## 研究問題

> **在不修改下游分析邏輯的前提下，如何將異質性爬蟲輸出（多種大學名稱格式、排名區間字串、不一致的國家縮寫）轉換為可直接比較的數值紀錄？**

## 模組結構

| 路徑 | 角色 |
|------|------|
| `c_engine/src/` | 核心正規化邏輯實作（C 語言）|
| `c_engine/include/` | 公開介面標頭檔 |
| `c_engine/Makefile` | 編譯腳本 |
| `c_engine/data/samples/` | 原始與正規化後的 CSV 樣本 |
| `c_engine/docs/architecture.md` | 模組架構與設計說明 |

**設計選擇**：以 C 實作核心引擎，而非使用 Python/pandas，rationale 是在大量 CSV 批次處理時維持低記憶體佔用與可預期的執行時間，同時避免引入 Python 執行期依賴。

## 使用說明（C 引擎）

### 1. 編譯引擎

```bash
cd c_engine
make
```

### 2. 準備輸入資料

將爬蟲產出的 CSV 放入範例資料目錄：

```bash
cp ../../universities_world.csv data/samples/raw_universities.csv
```

輸入 CSV 須包含以下欄位（欄位順序與名稱須符合）：

```
QS Rank,University,Country,GMAT,GRE,GPA,IELTS,TOEFL,Duolingo,Overall Score,URL
```

### 3. 執行正規化

```bash
make run
```

選單操作序列：

| 步驟 | 選單選項 | 動作 |
|------|---------|------|
| 1 | `1` | 載入 CSV 資料 |
| 2 | `3` | 執行完整正規化流程 |
| 3 | `4` | 預覽正規化後的結果 |
| 4 | `5` | 匯出結果為 `.csv` 檔 |
| 5 | `0` | 離開程式 |

### 4. 查看結果

正規化後的輸出預設儲存於：

```
data/samples/normalized_universities.csv
```

輸出格式：

```csv
University,Country,Rank Min,Rank Max,Overall Score
University of California Berkeley (Ucb),United States,12,14,91.70
```

## 驗證流程

### 單元測試

```bash
cd c_engine
make test
```

預期結果：

```
Passed: 17 / 17
All tests passed.
```

單元測試涵蓋的驗證範圍：

| 測試類別 | 驗證內容 |
|---------|---------|
| 大學名稱正規化 | 移除標點、轉小寫、壓縮空白 |
| 國家名稱正規化 | 縮寫展開（如 `U.S.A.` → `United States`）|
| 排名區間解析 | `53`、`101-150`、`Top 100` 等格式 |
| 分數解析 | 數字字串提取、無效值標記為 `-1` |
| CSV 讀寫與 escaping | 欄位分隔、引號處理 |

### 互動式整體測試

確認輸入檔存在：

```bash
ls data/samples/raw_universities.csv
```

再執行 `make run`，依序輸入：`1`、`3`、`4`、`5`、`0`。

### 一鍵快速驗證

```bash
printf '1\n3\n5\n0\n' | ./build/clawer_normalizer
```

若尚未編譯，先執行 `make`。

### 檢查輸出

```bash
sed -n '1,20p' data/samples/normalized_universities.csv
```

## 常見問題

| 問題 | 原因與處理方式 |
|------|--------------|
| `make test` 失敗 | 先執行 `make clean && make test` 重新編譯 |
| `載入失敗，請確認 CSV 檔案是否存在` | 確認 `data/samples/raw_universities.csv` 路徑正確 |
| CSV header 欄位數或欄名不符合預期 | reader 會拒絕載入；確認輸入 CSV 格式符合 11 欄規格 |
| 使用自訂資料 | 將 CSV 覆蓋至 `data/samples/raw_universities.csv` 後重新執行 |

## 開放問題

- 目前 `MAX_FIELDS = 11` 為硬編碼常數；若上游爬蟲增加欄位，reader 是否能優雅降級，還是需要修改常數？
- 國家名稱對照表目前是靜態的；當新的縮寫出現時，更新流程是否有可維護的機制？
- score parser 將無效分數標記為 `-1`；下游分析是否對此有明確的處理規則，還是依賴 writer 層的空值轉換？

## License

This project is licensed under the Apache License 2.0.
