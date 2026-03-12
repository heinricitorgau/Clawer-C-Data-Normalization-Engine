
# Clawer C Data Normalization Engine

**Clawer C 資料正規化引擎**

*A High‑Performance Data Cleaning Engine for University Datasets*

## 專案簡介

**Clawer C Data Normalization Engine（Clawer C 資料正規化引擎）** 是 Clawer 大學資料系統中的一個子模組，使用 **C 語言**實作資料清洗（Data Cleaning）與資料正規化（Data Normalization）功能。

此模組的主要目的，是將從不同來源（例如排名網站、學校官方網站或招生資訊頁面）取得的 **格式不一致、內容雜亂的大學資料**，轉換成 **乾淨、統一、可分析的結構化資料**。

在真實世界的資料集中，大學名稱、國家、排名、分數與申請條件往往會以不同格式出現，例如不同縮寫、不同標點符號或不同區間表示方式。這些差異會造成資料庫儲存、資料分析與推薦系統的困難。

本專案示範如何利用 **C 語言高效率處理大量文字資料**，並建立一個可以與 Python 系統整合的資料前處理模組。

---

## 專案特色

本專案具有以下特色：

- 使用 **C 語言實作資料清洗與正規化引擎**
- 採用 **模組化程式架構（Modular Architecture）**
- 可作為 **Python 系統的高效能資料前處理模組**
- 支援 **文字解析與結構化資料轉換**
- 可作為 **資料工程（Data Engineering）練習專案**

---

## 專案開發狀態

目前專案處於 **Prototype（原型）階段**。

已完成：

- 專案架構設計
- README 與系統說明
- 資料結構設計

開發中：

- Name normalization
- Country normalization
- Rank parser
- Score cleaning

未來計畫：

- Requirement parser
- Duplicate detection
- 與 Python 系統整合

---

---

## 在 Clawer 系統中的角色

在整個 Clawer 架構中，此模組位於 **資料解析與資料庫儲存之間的資料品質層（Data Quality Layer）**。

整體資料流程如下：

```
Crawler → Extractor → C Data Normalization Engine → Database / Export / Analytics
```

流程說明：

1. **Crawler**：從網站蒐集原始大學資料
2. **Extractor**：解析出結構化欄位（學校名稱、國家、排名、分數等）
3. **C Data Normalization Engine**：清洗並統一資料格式
4. 正規化後的資料可交由資料庫、分析模組或推薦系統使用

---

## 系統架構圖

```
             ┌──────────────┐
             │   Web Data   │
             │ (Ranking)    │
             └──────┬───────┘
                    │
                    ▼
             ┌──────────────┐
             │    Crawler   │
             └──────┬───────┘
                    │
                    ▼
             ┌──────────────┐
             │   Extractor  │
             └──────┬───────┘
                    │
                    ▼
      ┌─────────────────────────────┐
      │ C Data Normalization Engine │
      │  - Name normalization       │
      │  - Country normalization    │
      │  - Rank parsing             │
      │  - Score cleaning           │
      └──────────────┬──────────────┘
                     │
                     ▼
             ┌──────────────┐
             │   Database   │
             └──────────────┘
```

---

## 專案目標

本專案的主要目標包括：

- 展示 **C 語言模組化程式設計** 在資料處理中的應用
- 建立一個 **資料正規化引擎（Normalization Engine）**
- 改善資料在進入資料庫前的 **一致性與品質**
- 提供 **CLI（命令列）測試介面** 方便展示與除錯
- 作為 Python 系統的 **高效能資料前處理模組**

本專案同時展示 C 語言在以下方面的能力：

- 大量文字資料處理
- 記憶體效率控制
- 結構化資料轉換

---

## 為什麼使用 C 語言

Clawer 主系統主要使用 Python 開發，但某些資料處理工作使用 C 會更有效率。

在以下情境中，C 語言具有明顯優勢：

- 大量 **字串處理（String Processing）**
- 高頻率 **資料清洗與轉換**
- 較低的 **記憶體使用量**
- 可精細控制 **buffer 與 parsing 邏輯**

因此，本模組的定位是：

> 作為 Python 系統的 **高效能資料前處理引擎**。

---

## 主要功能

### 1. 大學名稱正規化

將不同格式的大學名稱轉換為統一表示方式。

範例：

```
University of California, Berkeley
UC Berkeley
U.C. Berkeley
UC-Berkeley
→ University of California Berkeley
```

處理方式可能包含：

- 移除多餘空白
- 移除標點符號
- 統一大小寫
- 基本別名（Alias）轉換

---

### 2. 國家名稱標準化

將不同表示方式的國家名稱統一為標準格式。

範例：

```
USA
U.S.A.
US
United States
→ United States
```

這能提升以下操作的準確性：

- 統計分析
- 篩選
- 依國家分類大學

---

### 3. 排名欄位解析

不同排名系統會使用不同表示方式，本模組會將其轉換為結構化數值。

範例：

```
"101-150"  → rank_min = 101, rank_max = 150
"201–250"  → rank_min = 201, rank_max = 250
"Top 100"  → rank_min = 1, rank_max = 100
"Rank 53"  → rank_min = 53, rank_max = 53
```

這可以支援：

- 排序
- 比較
- 篩選

---

### 4. 分數欄位清洗

處理不同格式的分數資料並轉為數值型態。

範例：

```
"98.4"
"Score: 98.4"
" 98.40 "
```

轉換為：

```
double score
```

---

### 5. 申請條件解析

從文字型的申請條件中提取結構化資訊。

範例：

```
IELTS 6.5 (no band below 6.0)
```

解析為：

```
overall_ielts = 6.5
min_band = 6.0
```

未來可擴充支援：

- TOEFL
- GPA
- 其他語言或入學條件

---

### 6. 重複資料檢測前處理

為了提升重複資料檢測（Duplicate Detection）的準確性，本模組會產生標準化比較字串，例如：

- 移除標點的名稱
- 全小寫名稱
- 壓縮空白的名稱

這些結果可作為後續 **實體比對（Entity Matching）** 的基礎。

---

## 專案結構

```
clawer_normalizer_c
│
├── main.c
├── normalizer.h
├── normalizer.c
│
├── name_normalizer.c
├── country_normalizer.c
├── rank_parser.c
├── score_parser.c
├── requirement_parser.c
│
├── utils.c
├── utils.h
│
├── data
│   ├── raw_universities.csv
│   └── normalized_universities.csv
│
└── README.md
```

---

## 檔案說明

| 檔案 | 功能 |
|-----|------|
| main.c | 程式進入點與 CLI 介面 |
| normalizer.h | 正規化函式宣告 |
| normalizer.c | 正規化流程控制 |
| name_normalizer.c | 大學名稱清洗 |
| country_normalizer.c | 國家名稱標準化 |
| rank_parser.c | 排名欄位解析 |
| score_parser.c | 分數資料處理 |
| requirement_parser.c | 申請條件解析 |
| utils.c / utils.h | 共用字串處理函式 |

---

## 資料結構設計

系統使用結構體管理原始資料與處理後資料：

```c
typedef struct {
    char raw_name[150];
    char normalized_name[150];
    char raw_country[80];
    char normalized_country[80];
    char raw_rank[50];
    int rank_min;
    int rank_max;
    char raw_score[50];
    double score;
} UniversityRecord;
```

此設計可同時保留：

- 原始資料（raw data）
- 正規化後資料（normalized data）

---

## CLI 示範介面

程式提供簡單的命令列操作介面：

```
==== Clawer C Data Normalization Engine ====

1. 顯示原始資料
2. 正規化大學名稱
3. 正規化國家名稱
4. 解析排名欄位
5. 清洗分數欄位
6. 執行完整正規化流程
7. 輸出正規化結果
0. 離開程式
```

此介面方便在課堂或專題報告中展示系統功能。

---

## 輸入與輸出

### 輸入

- CSV 檔案
- 測試資料集
- Clawer 爬蟲輸出的中介資料

### 輸出

- 清洗後的 CSV 資料
- 可匯入資料庫的結構化資料

資料流程示意：

```
Raw Data → Cleaning → Field Normalization → Structured Output
```

---

## 範例資料

### 輸入資料（Raw Data）

```
name,country,rank,score
UC Berkeley,USA,1-10,98.4
U.C. Berkeley,U.S.A.,Top 10,98.40
```

### 正規化後資料（Normalized Data）

```
name,country,rank_min,rank_max,score
University of California Berkeley,United States,1,10,98.4
University of California Berkeley,United States,1,10,98.4
```

此範例展示資料清洗與正規化後，可以將不同表示方式的資料轉換為一致的結構化格式。

---

---

## 編譯方式

使用 GCC 編譯：

```bash
gcc main.c normalizer.c name_normalizer.c country_normalizer.c rank_parser.c score_parser.c requirement_parser.c utils.c -o clawer_normalizer
```

執行程式：

```bash
./clawer_normalizer
```

---

## 與 Python 系統整合

本模組可透過多種方式與 Python 系統整合：

### 1. 檔案交換方式

```
Python Crawler
    ↓
Export CSV
    ↓
C Normalization Engine
    ↓
Clean CSV
    ↓
Python Database Module
```

### 2. Python 呼叫 C 函式

可透過以下方式整合：

- ctypes
- cffi
- Python C extension

---

## 未來發展方向

可能的未來擴充包括：

- 大學名稱別名字典
- 模糊比對（Fuzzy Matching）
- 重複資料偵測
- SQLite 直接整合
- 與 Python 版本清洗器的效能比較
- 多執行緒資料處理

---

## 教學與研究價值

本專案展示多項重要的計算機科學概念：

- C 語言資料處理
- 模組化軟體架構
- 字串解析與文字正規化
- C 與 Python 系統整合

本專案可作為：

- 課程專題
- 研究原型
- 系統工程練習

---

## 授權

本專案主要用於 **教學、研究與原型開發**。
