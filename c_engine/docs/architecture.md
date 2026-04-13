# C Data Normalization Engine — Architecture

## 設計目標與研究問題

> **在給定固定 CSV 欄位結構的前提下，最小化的 C 模組集合能否完整覆蓋大學排名資料的正規化需求，同時保持各模組的可獨立測試性？**

這個 engine 的設計選擇是將 pipeline 切分為獨立職責的模組（reader、normalizers、writer），而不是一個整合式的處理函式。rationale 是：任何一個正規化規則的變動（例如新增國家縮寫對照）應該只影響一個檔案，不應該要求重新理解整體流程。

## Pipeline 概觀

```
Raw CSV
   │
   ▼
CSV Reader          (src/csv_reader.c)
   │ — split rows, map columns, populate Record structs
   ▼
Normalization Pipeline  (src/normalizer.c)
   ├── Name Normalizer     (src/name_normalizer.c)
   ├── Country Normalizer  (src/country_normalizer.c)
   ├── Rank Parser         (src/rank_parser.c)
   └── Score Parser        (src/score_parser.c)
   │
   ▼
CSV Writer          (src/csv_writer.c)
   │
   ▼
Normalized CSV
```

## 輸入資料格式

系統預期輸入 CSV 的欄位順序如下（共 11 欄）：

```
QS Rank, University, Country, GMAT, GRE, GPA, IELTS, TOEFL, Duolingo, Overall Score, URL
```

目前使用的欄位：

| 欄位 | 用途 |
|------|------|
| `QS Rank` | 排名解析 |
| `University` | 名稱正規化 |
| `Country` | 國家正規化 |
| `Overall Score` | 分數解析 |

其餘欄位目前被忽略但保留在資料結構中，以利未來擴充使用。

**設計選擇**：`MAX_FIELDS = 11` 為硬編碼常數。rationale 是確保 reader 在欄位數不符預期時能明確拒絕載入，而不是靜默地對應到錯誤欄位。這會使得上游資料格式變動時立即可見，而不是產生難以追蹤的資料污染。

## 核心模組

### CSV Reader

**檔案**：`src/csv_reader.c`

| 職責 | 說明 |
|------|------|
| 載入 CSV 檔案 | 從指定路徑讀取原始資料 |
| 分割列與欄位 | 將每列切分為 `MAX_FIELDS` 個欄位 |
| 對應至內部資料結構 | 將欄位值填入 `Record` 的 raw 欄位 |
| 跳過 header 列 | 第一列不作為資料處理 |

### Record 結構

**檔案**：`include/record.h`

表示單筆大學紀錄。每筆紀錄同時保存原始值與正規化後的值，以利偵錯與差異比對。

| 欄位 | 類型 | 說明 |
|------|------|------|
| `raw_name` | string | 原始大學名稱 |
| `raw_country` | string | 原始國家欄位值 |
| `raw_rank` | string | 原始排名字串 |
| `raw_score` | string | 原始分數字串 |
| `normalized_name` | string | 正規化後的大學名稱 |
| `normalized_country` | string | 正規化後的國家名稱 |
| `rank_min` | int | 排名區間下界 |
| `rank_max` | int | 排名區間上界 |
| `score` | float | 解析後的數值分數（無效時為 `-1`）|

**設計選擇**：保留原始值（`raw_*`）而非直接覆寫，rationale 是正規化結果可以隨時與原始資料對照，且不需要重新載入即可重跑正規化流程。

### Normalization Pipeline

**檔案**：`src/normalizer.c`

協調所有正規化步驟的執行順序：

| 步驟 | 模組 | 說明 |
|------|------|------|
| 1 | Name Normalizer | 大學名稱正規化 |
| 2 | Country Normalizer | 國家名稱標準化 |
| 3 | Rank Parser | 排名字串解析為數值區間 |
| 4 | Score Parser | 分數字串解析為浮點數 |

### Name Normalizer

**檔案**：`src/name_normalizer.c`

| 操作 | 說明 |
|------|------|
| 移除標點符號 | 刪除影響比對的非語意標點 |
| 轉換為小寫 | 消除大小寫造成的名稱差異 |
| 壓縮多餘空白 | 統一內部空白為單一空格 |

### Country Normalizer

**檔案**：`src/country_normalizer.c`

以靜態對照表將縮寫或別名展開為標準國家名稱。

對照範例：

| 輸入 | 輸出 |
|------|------|
| `U.S.A.` | `United States` |
| `USA` | `United States` |
| `ROC` | `Taiwan` |

**開放問題**：對照表目前為靜態定義；新縮寫的加入需要重新編譯。若上游爬蟲資料來源增加新的國家表達方式，目前沒有不需要修改 source code 的擴充路徑。

### Rank Parser

**檔案**：`src/rank_parser.c`

將排名字串解析為 `rank_min` 與 `rank_max` 數值對。

支援的輸入格式：

| 輸入格式 | 範例 | 解析結果 |
|---------|------|---------|
| 單一整數 | `53` | min=53, max=53 |
| 區間字串 | `101-150` | min=101, max=150 |
| Top N 字串 | `Top 100` | min=1, max=100 |

**開放問題**：其他潛在格式（如 `=201`、`201+`）目前行為未定義；若上游排名資料引入新格式，parser 是否會靜默失敗或回傳可識別的錯誤值？

### Score Parser

**檔案**：`src/score_parser.c`

從字串中提取數值分數。

| 輸入範例 | 解析結果 |
|---------|---------|
| `98.4` | `98.4` |
| `Score: 91.25` | `91.25` |
| 無效或空值 | `-1` |

**設計選擇**：無效分數儲存為 `-1` 而非 `0` 或 `NaN`，rationale 是 `0` 是合法的邊界分數，應與「無資料」明確區分。

### CSV Writer

**檔案**：`src/csv_writer.c`

將正規化後的紀錄匯出為 CSV 檔案。

輸出欄位結構：

```
University,Country,Rank Min,Rank Max,Overall Score
```

| 欄位 | 來源 | 特殊規則 |
|------|------|---------|
| University | `normalized_name` | — |
| Country | `normalized_country` | — |
| Rank Min | `rank_min` | — |
| Rank Max | `rank_max` | — |
| Overall Score | `score` | 若 `score < 0`，輸出空值 |

## CLI 應用程式

**檔案**：`src/main.c`

提供互動式選單介面，允許逐步執行 pipeline 各階段：

| 選項 | 動作 |
|------|------|
| `1` | 載入 CSV 資料 |
| `2` | 顯示原始紀錄 |
| `3` | 執行完整正規化流程 |
| `4` | 顯示正規化後紀錄 |
| `5` | 匯出正規化 CSV |
| `0` | 離開程式 |

**設計選擇**：以互動選單而非單次命令列呼叫作為主要介面，rationale 是允許在同一次執行中分步驗證每個階段的輸出，降低偵錯成本。批次非互動執行可透過 stdin 重導向達成（見 README 的一鍵驗證指令）。

## 測試

**檔案**：`src/tests/test_normalizer.c`

| 測試類別 | 驗證內容 |
|---------|---------|
| 名稱正規化 | 標點移除、轉小寫、空白壓縮的正確性 |
| 國家正規化 | 縮寫對照展開的正確性 |
| 排名解析 | 三種格式的邊界情況 |
| 分數解析 | 有效值提取與無效值標記 |
| 完整 pipeline | 端對端的 Record 填充結果 |

執行指令：

```bash
make test
```

預期結果：`Passed: 17 / 17`

## 建構系統

| 指令 | 用途 |
|------|------|
| `make` | 編譯主程式 |
| `make run` | 編譯並執行互動式 CLI |
| `make test` | 編譯並執行單元測試 |
| `make clean` | 清除所有編譯產物 |

## 目錄結構

```
c_engine/
│
├── src/
│   ├── main.c
│   ├── csv_reader.c
│   ├── csv_writer.c
│   ├── normalizer.c
│   ├── name_normalizer.c
│   ├── country_normalizer.c
│   ├── rank_parser.c
│   ├── score_parser.c
│   └── utils.c
│
├── include/
│   ├── record.h
│   ├── csv_reader.h
│   ├── csv_writer.h
│   └── normalizer.h
│
├── src/tests/
│   └── test_normalizer.c
│
├── docs/
│   └── architecture.md
│
└── data/
    └── samples/
```

## 已知限制與待驗證問題

| 項目 | 說明 | 優先度 |
|------|------|--------|
| Header validation | 目前只驗證欄位數，不驗證欄名是否符合預期 | 高 |
| Quoted fields in CSV | 含逗號的欄位值（如大學名稱含 `, `）可能導致解析錯誤 | 高 |
| Streaming parser | 目前需一次載入全部資料；大型資料集的記憶體行為未測試 | 中 |
| Country table 擴充機制 | 新縮寫需修改 source code 並重新編譯 | 中 |
| Rank format edge cases | `201+`、`=201` 等格式的處理行為未定義 | 中 |
| Benchmarking | 目前無法量化各模組在不同資料規模下的處理時間 | 低 |
| CI integration | 尚未整合自動化測試流程 | 低 |
