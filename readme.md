# Clawer C Data Normalization Engine

高效能 C 語言資料正規化引擎，用於清洗與標準化大學資料集。

## 專案定位

此專案負責將來源不一致的學校資料轉換為可分析、可儲存的統一格式，典型流程如下：

`Raw CSV -> CSV Reader -> Normalization Pipeline -> CSV Writer`

可作為爬蟲或 ETL 流程中的 Data Quality Layer，先清洗再入庫。

## 目前已實作能力

- University 名稱正規化
  - 去除標點、轉小寫、去頭尾空白、壓縮連續空白
- Country 正規化
  - 支援常見別名映射（如 `U.S.A.` -> `United States`、`ROC` -> `Taiwan`）
- Rank 解析
  - 支援 `53`、`Rank 53`、`101-150`、`Top 100`、含 en/em dash 格式
- Score 解析
  - 可從字串中抽取第一個數值（如 `Score: 91.25`）
- Dataset Pipeline
  - 一次對整批 `UniversityRecord[]` 套用完整正規化
- CLI Demo
  - 載入資料、檢視 raw/normalized、輸出正規化 CSV
- Unit Tests
  - 針對核心 normalization/parsing 功能提供測試

## 專案結構

```text
.
├── include/
│   ├── record.h
│   ├── normalizer.h
│   ├── csv_reader.h
│   ├── csv_writer.h
│   └── utils.h
├── src/
│   ├── main.c
│   ├── normalizer.c
│   ├── name_normalizer.c
│   ├── country_normalizer.c
│   ├── rank_parser.c
│   ├── score_parser.c
│   ├── requirement_parser.c
│   ├── csv_reader.c
│   ├── csv_writer.c
│   ├── utils.c
│   └── tests/test_normalizer.c
├── data/samples/
│   ├── raw_universities.csv
│   └── normalized_universities.csv
├── docs/architecture.md
├── Makefile
└── readme.md
```

## 資料模型

核心資料結構為 `UniversityRecord`（`include/record.h`），同時保留 raw 與 normalized 欄位：

- Raw: `raw_name`, `raw_country`, `raw_rank`, `raw_score`
- Normalized: `normalized_name`, `normalized_country`, `rank_min`, `rank_max`, `score`

## CSV I/O 格式

目前 `csv_reader.c` 預期輸入為 5 欄：

`University,Country,Rank Min,Rank Max,Overall Score`

Reader 會把 `Rank Min` 與 `Rank Max` 合併成 `raw_rank`（例如 `101-150`）再交給 parser。

Writer 輸出格式同為：

`University,Country,Rank Min,Rank Max,Overall Score`

若分數無法解析（< 0），輸出時會留空。

## Build 與執行

需求：

- GCC（支援 C11）
- `make`

常用指令：

```bash
make          # 編譯主程式 -> build/clawer_normalizer
make run      # 執行 CLI
make test     # 執行單元測試
make clean    # 清除編譯產物
make rebuild  # clean + make
```

## CLI 使用流程

執行 `make run` 後，選單流程如下：

1. 載入 CSV（預設讀取 `data/samples/raw_universities.csv`）
2. 顯示原始資料
3. 執行完整正規化
4. 顯示正規化結果
5. 匯出 CSV（預設輸出 `data/samples/normalized_universities.csv`）

## 測試

`make test` 會建立並執行 `build/test_normalizer`，覆蓋：

- `normalize_name`
- `normalize_country`
- `parse_rank`
- `parse_score`
- `normalize_record` pipeline

## 模組說明

- `src/normalizer.c`
  - Pipeline orchestration，依序呼叫 name/country/rank/score 模組
- `src/name_normalizer.c`
  - 名稱清洗與格式標準化
- `src/country_normalizer.c`
  - 國家別名對照與標準化
- `src/rank_parser.c`
  - 排名字串解析為 `rank_min/rank_max`
- `src/score_parser.c`
  - 分數字串抽值為 `double`
- `src/utils.c`
  - 共用字串工具（trim/lowercase/remove punctuation/collapse spaces）
- `src/csv_reader.c`
  - 載入 CSV 並映射到 `UniversityRecord`
- `src/csv_writer.c`
  - 匯出 normalized CSV

## 已知限制

- CSV parser 目前為簡化版，使用逗號切分，不支援引號包覆的複雜欄位
- `MAX_RECORDS` 目前在 `src/main.c` 固定為 `100`
- `requirement_parser.c` 已納入編譯，但尚未實作功能
- Country alias map 仍屬基礎版本，可持續擴充

## Roadmap 建議

- 改成 robust CSV parser（支援 quoted fields）
- 增加欄位驗證與錯誤報告機制
- 擴充 country/name alias dictionary
- 新增 benchmark 與壓力測試
- 補齊 `requirement_parser` 與更多業務規則

## License

本專案採用 `LICENSE` 中所定義的授權條款。
