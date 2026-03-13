

# Clawer C Data Normalization Engine 架構說明

## 1. 架構定位

**Clawer C Data Normalization Engine** 是 Clawer 主系統中的資料前處理子模組，負責將爬蟲與解析器產生的原始大學資料，轉換成可儲存、可查詢、可分析的標準化資料。

在整體 Clawer 資料流程中，本模組位於：

```text
Crawler → Extractor → C Data Normalization Engine → Database / Export / Analytics
```

也就是說，本模組的任務不是直接負責爬取資料，也不是最終分析與推薦，而是作為 **資料品質層（Data Quality Layer）**，處理欄位格式混亂、命名不一致、數值表示方式不同等問題。

---

## 2. 架構目標

本模組的設計目標如下：

- 將不同來源的大學資料統一成一致格式
- 降低資料重複、命名不一致與格式錯誤問題
- 提供可重複使用的 C 語言正規化元件
- 與 Python 主系統維持清楚的模組邊界
- 支援 CLI 展示、測試與未來擴充

---

## 3. 系統分層

目前架構可分為五層：

### 3.1 輸入層（Input Layer）

負責接收原始資料。

來源包括：

- `data/samples/raw_universities.csv`
- 由 Clawer Python 系統匯出的 CSV 中介資料
- 未來可擴充為其他文字資料來源

代表模組：

- `src/csv_reader.c`
- `include/csv_reader.h`

主要責任：

- 讀取 CSV 檔案
- 跳過表頭（header）
- 將每一列資料載入 `UniversityRecord`
- 建立供後續正規化使用的原始資料陣列

---

### 3.2 資料模型層（Data Model Layer）

負責定義整個系統共用的資料結構。

代表模組：

- `include/record.h`

核心資料結構：

```c
typedef struct {
    char raw_name[150];
    char raw_country[80];
    char raw_rank[50];
    char raw_score[50];

    char normalized_name[150];
    char normalized_country[80];

    int rank_min;
    int rank_max;
    double score;
} UniversityRecord;
```

此層的角色是作為整個 normalization pipeline 的共通資料載體，保留：

- 原始輸入資料（raw fields）
- 正規化後結果（normalized fields）

---

### 3.3 正規化流程控制層（Normalization Orchestration Layer）

負責協調各個正規化子模組，將單筆或整批資料完成轉換。

代表模組：

- `src/normalizer.c`
- `include/normalizer.h`

核心函式：

- `normalize_record()`
- `normalize_dataset()`

資料流程如下：

```text
UniversityRecord
   ├── normalize_name()
   ├── normalize_country()
   ├── parse_rank()
   └── parse_score()
        ↓
Normalized UniversityRecord
```

此層本身不直接處理底層字串細節，而是負責：

- 呼叫各個欄位處理模組
- 控制整體正規化順序
- 對單筆與多筆資料提供一致介面

---

### 3.4 欄位正規化模組層（Field Normalization Modules）

負責各欄位的具體轉換邏輯。

#### 3.4.1 名稱正規化

代表模組：

- `name_normalizer.c`

主要責任：

- 去除前後空白
- 移除標點符號
- 轉小寫
- 壓縮多餘空白

範例：

```text
U.C. Berkeley -> uc berkeley
University of California, Berkeley -> university of california berkeley
```

---

#### 3.4.2 國家名稱正規化

代表模組：

- `country_normalizer.c`

主要責任：

- 清洗國家名稱字串
- 建立常見別名映射
- 輸出 canonical country name

範例：

```text
USA -> United States
U.S.A. -> United States
ROC -> Taiwan
```

---

#### 3.4.3 排名解析

代表模組：

- `rank_parser.c`

主要責任：

- 將原始排名字串轉為結構化數值範圍
- 支援單值、區間與 Top-N 格式

範例：

```text
53 -> rank_min=53, rank_max=53
101-150 -> rank_min=101, rank_max=150
Top 100 -> rank_min=1, rank_max=100
```

---

#### 3.4.4 分數解析

代表模組：

- `score_parser.c`

主要責任：

- 從文字中擷取第一個有效數值
- 轉換為 `double`
- 解析失敗時回傳預設值

範例：

```text
Score: 98.4 -> 98.4
 98.40  -> 98.4
```

---

#### 3.4.5 申請條件解析（預留擴充）

代表模組：

- `requirement_parser.c`

目前定位：

- 預留未來擴充 admission requirement parsing
- 後續可支援 IELTS、TOEFL、GPA 等欄位抽取

---

### 3.5 共用工具層（Utility Layer）

負責提供各模組共用的字串處理函式。

代表模組：

- `src/utils.c`
- `include/utils.h`

目前提供的工具函式包括：

- `trim_whitespace()`
- `to_lowercase()`
- `collapse_spaces()`
- `remove_punctuation()`
- `safe_copy_string()`

此層的目的，是將重複邏輯抽離，避免：

- 每個模組各自實作一套類似字串清洗流程
- 維護成本增加
- 規則修改後無法一致更新

---

## 4. 執行流程

使用者透過 CLI 與系統互動時，完整流程如下：

```text
1. 使用者啟動程式
2. main.c 顯示 CLI 選單
3. 使用者選擇載入 CSV
4. csv_reader.c 將資料讀入 UniversityRecord 陣列
5. normalizer.c 呼叫各欄位模組執行正規化
6. main.c 顯示正規化結果
7. 未來可擴充輸出 CSV 或寫入資料庫
```

對應模組順序如下：

```text
main.c
  ↓
csv_reader.c
  ↓
normalizer.c
  ↓
[name_normalizer.c | country_normalizer.c | rank_parser.c | score_parser.c]
  ↓
結果輸出 / 顯示
```

---

## 5. 目前目錄結構

```text
clawer-normalizer-c/
├── README.md
├── LICENSE
├── Makefile
├── docs/
│   └── architecture.md
├── include/
│   ├── csv_reader.h
│   ├── normalizer.h
│   ├── record.h
│   └── utils.h
├── src/
│   ├── main.c
│   ├── csv_reader.c
│   ├── csv_writer.c
│   ├── normalizer.c
│   └── utils.c
├── data/
│   └── samples/
│       ├── raw_universities.csv
│       └── normalized_universities.csv
├── tests/
│   └── test_normalizer.c
├── name_normalizer.c
├── country_normalizer.c
├── rank_parser.c
├── score_parser.c
└── requirement_parser.c
```

---

## 6. 模組依賴關係

目前主要依賴關係如下：

```text
main.c
 ├── csv_reader.h
 ├── normalizer.h
 └── record.h

normalizer.c
 ├── normalizer.h
 └── record.h

csv_reader.c
 ├── csv_reader.h
 └── record.h

name_normalizer.c
 └── utils.h

country_normalizer.c
 ├── utils.h
 └── string.h

rank_parser.c
 └── stdio.h

score_parser.c
 └── stdio.h

utils.c
 └── utils.h
```

從架構角度來看：

- `main.c` 是入口層
- `normalizer.c` 是流程控制層
- `name/country/rank/score` 是業務邏輯層
- `utils.c` 是基礎工具層
- `record.h` 是共通資料模型

---

## 7. 架構優點

目前這個架構具備以下優點：

### 7.1 模組化清楚

每個欄位處理都有獨立責任，不會把所有邏輯混在同一個檔案中。

### 7.2 易於維護

若未來要修改名稱正規化規則，只需調整 `name_normalizer.c` 或 `utils.c`，不必影響其他模組。

### 7.3 易於擴充

未來可逐步加入：

- alias dictionary
- duplicate detection
- fuzzy matching
- SQLite writer
- benchmark module

### 7.4 易於與 Python 整合

這個架構未來可透過：

- CSV 檔案交換
- `ctypes`
- `cffi`
- Python C extension

與 Clawer Python 主系統整合。

---

## 8. 目前限制

目前架構雖然已具備 prototype 基礎，但仍有幾個限制：

- 部分欄位模組仍屬第一版實作
- CSV parser 尚未完整支援 quoted comma
- 某些模組仍位於專案根目錄，未完全移入 `src/`
- requirement parsing 尚未正式實作
- 尚未加入完整單元測試與 benchmark

---

## 9. 未來架構演進方向

下一步可考慮的演進方向：

### 9.1 目錄結構統一

將所有 parser / normalizer 模組移入 `src/`，例如：

```text
src/
├── name_normalizer.c
├── country_normalizer.c
├── rank_parser.c
├── score_parser.c
└── requirement_parser.c
```

### 9.2 測試層強化

在 `tests/` 中加入：

- `test_name_normalizer.c`
- `test_country_normalizer.c`
- `test_rank_parser.c`
- `test_score_parser.c`

### 9.3 輸出層完善

補齊 `csv_writer.c` 與輸出功能，使系統可以：

```text
Raw CSV → Normalize → Export Clean CSV
```

### 9.4 與主專案深度整合

將本模組作為 Clawer Python 系統的高效能 normalization backend。

---

## 10. 總結

Clawer C Data Normalization Engine 的核心架構是一個 **以 C 語言實作的資料品質處理層**，設計重點不在於取代主系統，而在於補足 Python 在高頻率字串處理與資料正規化上的底層能力。

目前的架構已具備：

- 輸入層
- 資料模型層
- 流程控制層
- 欄位正規化模組層
- 共用工具層

這樣的設計使本專案同時具備：

- 獨立專題展示價值
- 與 Clawer 主系統整合能力
- 後續擴充為更完整資料工程模組的潛力
