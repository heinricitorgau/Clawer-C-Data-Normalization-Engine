# 綜合測試實驗報告（Day 1 + Day 2）

**專案：** crawlernest-normalization — C 資料正規化引擎  
**整合日期：** 2026-04-13  
**涵蓋期間：** Day 1（2026-04-12）＋ Day 2（2026-04-13）  
**整理者：** 自動化實驗系統（Claude）

---

## 1. 報告目的

本文件整合兩次連續實驗：

- **Day 1：Extreme Stress & Edge-Case 測試**
- **Day 2：Weakness-Oriented 弱點分析與回歸測試**

整合後的目標是用一份文件回答三個問題：

1. 這兩天各自發現了哪些問題
2. 哪些問題已被修復，哪些仍屬已知限制
3. 目前引擎的最新可驗證測試覆蓋與總結果是什麼

---

## 2. 兩日實驗摘要

| 日次 | 主題 | 新增測試 | 修復問題 | 結果 |
|---|---|---:|---:|---|
| Day 1 | Extreme Stress & Edge-Case | 140 | 14 | 原始 17 + extreme 140 全綠 |
| Day 2 | Weakness Analysis & Regression | 42 | 2 | 既有 187 + weakness 42 全綠 |

### 2.1 核心結論

- **Day 1** 主要補強的是極限輸入、country alias、acronym 與長 token 邊界問題。
- **Day 2** 主要補強的是弱點導向測試，特別是 `=N` 排名格式與 `/` 後大小寫處理。
- **目前最新可驗證狀態** 以 Day 2 結果為主：**229 / 229 PASS**。

---

## 3. Day 1（2026-04-12）— Extreme Stress & Edge-Case

### 3.1 Day 1 基準

在新增任何極限測試前，既有測試先執行一次：

| Suite | Result |
|---|---|
| `make test` (`test_normalizer`) | **17 / 17 PASS** |

### 3.2 Day 1 新增內容

新增 `build/test_extreme`，涵蓋：

- 12 個 stress categories
- 140 個 individual assertions

主要測試主題：

- NULL / empty safety
- single-character handling
- buffer boundaries
- Unicode / multi-byte passthrough
- adversarial / injection-like inputs
- country alias exhaustion
- abbreviation expansion
- idempotency
- rank parsing edge cases
- score parsing edge cases
- name normalization edge cases
- throughput（10,000 records）

### 3.3 Day 1 發現的主要問題（14 項）

Day 1 的失敗集中在兩類：

#### A. 名稱正規化問題

- 長 token 因 `word[64]` 被截斷後，產生 phantom split
- `"(UCB)"`、`"(MIT)"` 這類帶括號 acronym 未被正確識別
- `KAIST`、`POSTECH`、`LSE` 等 acronym list 不一致，導致被錯誤 title-case

#### B. 國家 alias 缺漏

- `britain`
- `england`
- `scotland`
- `wales`
- `northern ireland`
- `mainland china`
- `prc`
- `peoples republic of china`

### 3.4 Day 1 修復內容

#### 修復 1：`c_engine/src/name_normalizer.c`

- 將 `expand_common_abbreviations` 與 `apply_readable_name_case` 內的 `char word[64]` 擴大為 `NAME_WORK_LEN`
- 在 `is_name_acronym` 中加入一層括號剝除邏輯
- 補齊 acronym list：KAIST、POSTECH、LSE、KTH、ANU、UNSW、CUHK、UBA、UNAM

#### 修復 2：`c_engine/src/country_normalizer.c`

新增 8 個缺漏 aliases，補齊 UK 與 China (Mainland) 常見變體。

#### 修復 3：`c_engine/Makefile`

新增 `test_extreme` target，讓極限測試可以獨立執行。

### 3.5 Day 1 結果

| Suite | Result |
|---|---|
| `make test` | **17 / 17 PASS** |
| `make test_extreme` | **140 / 140 PASS** |
| **Combined** | **157 / 157 PASS** |

### 3.6 Day 1 留下的已知限制

- UTF-8 多位元組字首無法在 C locale 下自動大寫化
- `-1.0` 同時是 score parser 的 error sentinel 與數學上合法值
- rank range 不檢查 `min <= max`
- `requirement_parser.c` 仍是 placeholder

---

## 4. Day 2（2026-04-13）— Weakness Analysis & Regression

### 4.1 Day 2 基準

在 Day 2 開始時，既有測試結果如下：

| 測試套件 | 結果 |
|---|---|
| `test_normalizer` | **17 / 17 PASS** |
| `test_extreme` | **139 / 139 PASS** |
| `test_scale` | **31 / 31 PASS** |
| **合計** | **187 / 187 PASS** |

註：Day 2 基準將 `test_extreme` 視為 **139 tests**；因此本報告保留 Day 1 與 Day 2 的原始記錄，不強行改寫單日歷史統計。

### 4.2 Day 2 新增內容

新增 `c_engine/src/tests/test_weakness.c`，共 **42 個 weakness-oriented tests**。

涵蓋主題：

- `=N` rank format
- `N+` rank format
- `#N` rank format（文件化既有行為）
- integer overflow resilience
- negative score ambiguity
- score trailing noise
- `&` 保留
- `/` 後大寫化
- country fallback
- reversed rank record
- header-only CSV
- UTF-8 BOM CSV
- integration cases

### 4.3 Day 2 發現並修復的問題（2 項）

#### Bug-1 — `rank_parser.c` 未處理 `=N` 格式

| 項目 | 內容 |
|---|---|
| 症狀 | `parse_rank("=201")` 解析失敗，得到 `-1 / -1` |
| 預期 | `201 / 201` |
| 原因 | `sscanf` pattern list 中沒有 `=N` case |
| 修復 | 在 plain integer 前新增 `sscanf(" =%d", &a)` case |
| 重要度 | 高 — QS ranking data 中實際會出現 |

#### Bug-2 — `name_normalizer.c` 斜線後字元未大寫化

| 項目 | 內容 |
|---|---|
| 症狀 | `normalize_name("Arts/Sciences")` 變成 `"Arts/sciences"` |
| 預期 | `"Arts/Sciences"` |
| 原因 | `capitalize_next` 只在 `-` 與 `(` 後觸發，未包含 `/` |
| 修復 | 改為 `capitalize_next = (ch == '-' || ch == '(' || ch == '/')` |
| 重要度 | 中 — 大學名稱與院系名稱中實際可能出現 |

### 4.4 Day 2 文件化但未修復的設計限制

| ID | 位置 | 內容 | 判斷 |
|---|---|---|---|
| W3 | `rank_parser.c` | `#N` 格式未支援 | 可列入後續優先順序 |
| W4 | `rank_parser.c` | 非常大整數可能在 `%d` 解析時溢位 | 實務風險低 |
| W5 | `score_parser.c` | `-1.0` 與 sentinel 衝突 | 目前可接受 |
| W10 | `csv_writer.c` | 寫入 `rank_min > rank_max` 不驗證 | 可交由下游處理 |

### 4.5 Day 2 結果

| 測試套件 | 結果 |
|---|---|
| `test_normalizer` | **17 / 17 PASS** |
| `test_extreme` | **139 / 139 PASS** |
| `test_scale` | **31 / 31 PASS** |
| `test_weakness` | **42 / 42 PASS** |
| **全部合計** | **229 / 229 PASS** |

---

## 5. 兩日修改檔案整合

| 檔案 | Day 1 | Day 2 | 說明 |
|---|---|---|---|
| `c_engine/src/name_normalizer.c` | ✅ | ✅ | Day 1 修 acronym / long token；Day 2 修 `/` 後大小寫 |
| `c_engine/src/country_normalizer.c` | ✅ | — | 補國家 alias |
| `c_engine/src/rank_parser.c` | — | ✅ | 補 `=N` rank format |
| `c_engine/Makefile` | ✅ | ✅ | Day 1 新增 `test_extreme`；Day 2 新增 `test_weakness` / `test_all` |
| `c_engine/src/tests/test_extreme.c` | ✅ | — | Day 1 新增 extreme suite |
| `c_engine/src/tests/test_weakness.c` | — | ✅ | Day 2 新增 weakness suite |
| `TEST_RECORD.md` | ✅ | — | Day 1 原始報告 |
| `test-report.md` | — | ✅ | Day 2 報告，現已整合為本文件 |

---

## 6. 當前測試版圖

截至 Day 2，測試版圖已包含：

| Suite | 目的 | 最新結果 |
|---|---|---|
| `test_normalizer` | 原始單元測試 | **17 / 17 PASS** |
| `test_extreme` | 極限、邊界與吞吐測試 | **139 / 139 PASS** |
| `test_scale` | 規模與載入測試 | **31 / 31 PASS** |
| `test_weakness` | 弱點導向回歸測試 | **42 / 42 PASS** |
| **總計** | | **229 / 229 PASS** |

---

## 7. 尚待改善的方向

| 優先順序 | 項目 | 說明 |
|---|---|---|
| 高 | `rank_parser`：支援 `#N` 格式 | 例如 `#10` |
| 中 | `rank_parser`：整數溢位保護 | 先以 `long` 解析再檢查範圍 |
| 中 | `csv_writer`：反轉排名警告 | `rank_min > rank_max` 時可輸出警示 |
| 低 | `score_parser`：替換 sentinel | 考慮 `NaN` 或獨立狀態旗標 |
| 低 | CI 整合 | 把 `test_all` 接入自動化流程 |

---

## 8. 結論

這兩天的實驗可以視為兩個互補階段：

- **Day 1**：先把極限輸入與明顯邊界問題打穿，確認引擎在 stress 條件下不會崩潰，且 country/name normalization 的常見缺漏被補齊。
- **Day 2**：再以 weakness-oriented 方式精準補測，修掉 `=N` 排名格式與 `/` 後大小寫這兩個更接近真實資料處理的缺口。

最新整合後，可採信的現況是：

> **crawlernest-normalization 的 C 正規化引擎目前共有 4 個測試套件、229 個測試案例，全部通過。**

原始分日報告仍保留於：

- [TEST_RECORD.md](/Users/test/Desktop/crawlernest-normalization/TEST_RECORD.md)
- [test-report.md](/Users/test/Desktop/crawlernest-normalization/test-report.md)

---

*整合完成：2026-04-13*
