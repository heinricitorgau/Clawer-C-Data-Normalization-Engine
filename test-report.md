# Clawer C 資料正規化引擎 — 實驗性測試報告

**專案**：Clawer C Data Normalization Engine  
**報告日期**：2026-04-19  
**測試總覽**：7 套測試套件，共 **446 / 446** 全數通過

---

## 一、系統架構概覽

本引擎以 C11 撰寫，接收原始大學排名 CSV，輸出正規化後的 CSV 檔案。

輸入格式（5 欄）：`University, Country, Rank Min, Rank Max, Overall Score`

處理管線：
```text
CSV Reader → Name Normalizer → Country Normalizer → Rank Parser → Score Parser → CSV Writer
```

主要元件：

| 元件 | 負責功能 |
|------|---------|
| `csv_reader.c` | 解析 CSV，處理引號跳脫、多餘欄位、格式錯誤與 BOM |
| `name_normalizer.c` | 大學名稱標題化、縮寫保留、別名清理 |
| `country_normalizer.c` | 國家別名正規化，查無對映時回退為 Title Case |
| `rank_parser.c` | 解析排名字串（`53`、`101-150`、`Top 100`、`=201`、`#10`、`201+` 等） |
| `score_parser.c` | 解析評分浮點數，無效輸入回傳哨兵值 `-1.0` |
| `csv_writer.c` | 輸出正規化後的 CSV，處理 quoting / escaping |

---

## 二、Session 1 測試（2026-04-13）

### 2.1 測試目標

對初版程式碼進行系統性弱點分析，識別未覆蓋的邊界情境並修正。

### 2.2 發現的弱點及修正

**W1 — `rank_parser`：`=N` 格式未支援**  
問題：QS 等排名來源使用 `=201` 表示「並列第 201」，原程式回傳 `-1/-1`。  
修正：在 `parse_rank()` 新增 Case 4，以 `sscanf(temp, " =%d", &a)` 處理。

**W2 — `rank_parser`：`N+` 格式**  
`201+` 代表「名次在 201 名之後」。確認 `sscanf %d` 在 `+` 前停止，已能正確解析（201/201），無需修改。

**W3 — `rank_parser`：`#N` 格式（Session 1 文件化，Session 2 修正）**  
Session 1 確認 `#10` 回傳 `-1/-1`，列為已知限制；Session 2 完成修正。

**W4 — `rank_parser`：整數溢位不崩潰**  
確認 `99999999999999` 等超大值不造成崩潰。

**W5 — `score_parser`：負分哨兵碰撞（設計弱點）**  
`-1.0` 輸入與「無資料」哨兵值相同，無法區分。已文件化，不修改。

**W6 — `score_parser`：帶額外文字的分數**  
確認 `sscanf` 在非數字字元處停止，`91.2 pts` 可解析為 `91.2`。

**W7 — `name_normalizer`：`&` 符號保留**  
確認 `&` 不被 `normalize_name_punctuation` 刪除。

**W8 — `name_normalizer`：`/` 後首字母未大寫**  
問題：`University of X/Y Campus` 會變成 `University of X/y Campus`。  
修正：`apply_readable_name_case()` 的 `capitalize_next` 觸發條件加入 `'/'`。

```c
capitalize_next = (ch == '-' || ch == '(' || ch == '/');
```

**W9 — `country_normalizer`：主要國家以 title-case 回退**  
確認 Japan、Germany、France 等以 `to_title_case()` 處理，輸出正確。

**W10 — `csv_writer`：倒置排名不驗證（設計缺口）**  
`rank_min > rank_max` 時直接寫出，未額外驗證，已文件化。

**W11 — `csv_reader`：僅含標頭的 CSV**  
確認 `load_csv_data()` 回傳 0 筆，不崩潰。

**W12 — `csv_reader`：UTF-8 BOM**  
確認帶有 BOM（EF BB BF）的 CSV 能正確讀取。

### 2.3 Session 1 測試結果

| 測試套件 | 通過 / 總計 |
|---------|-----------|
| `test_normalizer`（基礎單元測試） | 17 / 17 |
| `test_extreme`（壓力與邊界） | 139 / 139 |
| `test_scale`（大規模生產模擬） | 31 / 31 |
| `test_weakness`（弱點回歸） | 42 / 42 |
| **Session 1 合計** | **229 / 229** |

---

## 三、Session 2 測試（2026-04-15）

### 3.1 測試目標

在 Session 1 修正基礎上，進行第二輪深度靜態審查，識別新的四類弱點並驗證修正。

### 3.2 發現的弱點及修正

#### 弱點 A — `name_normalizer`：小寫連接詞清單不完整

問題：`is_lowercase_connector()` 僅列出 `of`、`and`、`the`、`for` 四個詞，缺少常見介系詞。

修正前失敗案例：

| 輸入 | 期望輸出 | 修正前實際輸出 |
|------|---------|--------------|
| `School of Arts in London` | `School of Arts in London` | `School of Arts In London` |
| `Institute of Mathematics at Cambridge` | `Institute of Mathematics at Cambridge` | `Institute of Mathematics At Cambridge` |
| `Letter to the Editor` | `Letter to the Editor` | `Letter To the Editor` |
| `Submitted by the Author` | `Submitted by the Author` | `Submitted By the Author` |

修正：`is_lowercase_connector()` 新增 6 個條目（`in/at/to/by/a/an`），首詞仍大寫。

#### 弱點 B — `country_normalizer`：別名表不完整

修正前失敗案例：

| 輸入 | 期望 | 修正前輸出 |
|------|------|----------|
| `Korea, Republic of` | `South Korea` | `Korea Republic Of` |
| `DPRK` | `North Korea` | `Dprk` |
| `MY` | `Malaysia` | `My` |
| `UAE` | `United Arab Emirates` | `Uae` |

修正：`mapping_table[]` 新增 28 個條目，涵蓋倒裝變體、北韓、ISO 代碼及常見全稱。

#### 弱點 C — `rank_parser`：`#N` 格式未支援

問題：`#10` 等 hash 前綴格式回傳 `-1/-1`。  
修正：新增 Case 5，`sscanf(temp, " #%d", &a)`，同步更新 `test_weakness` W3 期望值。

#### 弱點 D — `rank_parser`：負數排名未拒絕

問題：`"-100"` 被解析為 `-100/-100`，而非哨兵值 `-1/-1`。  
修正：所有 `sscanf` 成功後新增 `if (a < 0) { return; }` 檢查。

### 3.3 新增測試套件：`test_regression2`

新增 `src/tests/test_regression2.c`（60 個測試案例，全以繁體中文標籤）：

| 測試分組 | 案例數 |
|---------|-------|
| A — 小寫連接詞 | 13 |
| B — 國家別名 | 17 |
| C — `#N` 排名格式 | 8 |
| D — 負數排名驗證 | 6 |
| 整合測試 | 9 |
| 額外（score/writer 邊界） | 7 |
| **合計** | **60** |

### 3.4 Session 2 測試結果

| 測試套件 | 修正前通過 | 修正後通過 |
|---------|-----------|----------|
| `test_regression2` | 39 / 60 | 60 / 60 |
| `test_weakness`（W3 更新） | 42 / 43 | 43 / 43 |

---

## 四、Session 3 測試（2026-04-15）

### 4.1 發現的弱點

**Fix E — `country_normalizer.c`：含連字號國家名稱**  
`remove_punctuation()` 使用 `ispunct()` 刪除連字號，造成 `"Timor-Leste"` 變成 `"Timorleste"`。  
修正：在 `normalize_basic()` 中先將連字號替換為空格，並補充 mapping table 別名。

**Fix F — `utils.c`：`to_title_case()` 小寫連接詞清單不完整**  
原只保留 `"of"` 為小寫。修正後新增 `and/the/for/in/at/to/by/a/an`。

**Fix G — `name_normalizer.c`：`"Tech"` 誤展開為 `"Technology"`**  
Georgia Tech、Texas Tech、Virginia Tech 等名稱被靜默破壞。修正：移除此對映。

**Fix H — `csv_writer.c`：CSV 欄位數不正確**  
`rank_min < 0` 時輸出空欄的格式不正確，僅產生 4 欄。修正後可維持正確 5 欄輸出。

### 4.2 新增測試

`src/tests/test_regression3.c`（71 項）：覆蓋 E/F/G/H 四類弱點、冪等性、整合測試與邊界案例。

### 4.3 全套測試結果（Session 3 後）

| 套件 | 項數 | 結果 |
|------|------|------|
| `test_normalizer` | 17 | ✅ |
| `test_extreme` | 139 | ✅ |
| `test_scale` | 31 | ✅ |
| `test_weakness` | 43 | ✅ |
| `test_regression2` | 60 | ✅ |
| `test_regression3` | 71 | ✅ |
| **合計** | **361** | ✅ **361/361** |

---

## 五、Session 4 測試（2026-04-19）

### 5.1 實驗探針方法

對所有模組原始碼進行靜態分析後，針對可疑路徑撰寫 C 探針程式直接執行，確認實際輸出與預期落差，再分類為具體弱點。

### 5.2 發現的弱點

**Bug I — `rank_parser.c`：`Top` / `Rank` 前綴大小寫不敏感未完整實作**

| 輸入 | 修正前 | 修正後 |
|------|--------|--------|
| `"TOP 100"` | `-1/-1` | `1/100` |
| `"RANK 53"` | `-1/-1` | `53/53` |
| `"TOP50"`（無空格） | `-1/-1` | `1/50` |

原實作僅以固定字面量匹配，無法處理全大寫變體。

**Bug J — `country_normalizer.c`：別名表缺少常見資料集變體**

| 輸入 | 修正前 | 修正後 |
|------|--------|--------|
| `"Korea, Rep."` | `"Korea Rep"`（fallback） | `"South Korea"` |
| `"Korean Dem. People's Rep."` | `"Korea Dem Peoples Rep"` | `"North Korea"` |
| `"Russian Federation"` | `"Russian Federation"` | `"Russia"` |
| `"Macao"` / `"Macau"` | `"Macao"` / `"Macau"` | `"Macao SAR"` |
| `"Czechia"` | `"Czechia"`（fallback） | `"Czech Republic"` |

**Bug K — `name_normalizer.c` / `utils.c`：大學縮寫清單不完整**

下列常見縮寫未在清單中，導致降為 Title Case：

| 輸入 | 修正前 | 修正後 |
|------|--------|--------|
| `"ETH Zurich"` | `"Eth Zurich"` | `"ETH Zurich"` |
| `"UBC Vancouver"` | `"Ubc Vancouver"` | `"UBC Vancouver"` |
| `"HKUST"` | `"Hkust"` | `"HKUST"` |
| `"TUM"` | `"Tum"` | `"TUM"` |
| `"TU Munich"` | `"Tu Munich"` | `"TU Munich"` |
| `"IIT Delhi"` | `"Iit Delhi"` | `"IIT Delhi"` |
| `"RMIT University"` | `"Rmit University"` | `"RMIT University"` |

**Bug L — `rank_parser.c`：`sscanf %d` 整數溢位繞回正數**

`"9999999999"` 用 `sscanf` 的 `%d` 解析，溢位後繞回正值，通過 `< 0` 檢查，產生非意義排名值。  
修正：改用 `strtol`，並加上 `MAX_REASONABLE_RANK = 9,999,999` 上限檢查。

| 輸入 | 修正前 | 修正後 |
|------|--------|--------|
| `"9999999999"` | `1410065407/1410065407` | `-1/-1` |
| `"2147483648"` | `-1/-1`（偶然負值） | `-1/-1` |
| `"9999999"` | 正常解析 | `9999999/9999999` |
| `"10000000"` | 正常解析 | `-1/-1`（超過上限） |

### 5.3 修正詳情

**Fix I**（`rank_parser.c`）：新增 `str_prefix_icase()` 輔助函式，重寫 Top 與 Rank 的大小寫不敏感匹配。  
**Fix J**（`country_normalizer.c`）：在 `mapping_table[]` 新增 14 個別名條目，涵蓋韓國縮寫、俄羅斯、澳門、捷克、伊朗、越南等常見格式。  
**Fix K**（`name_normalizer.c` + `utils.c`）：兩個縮寫清單同步新增 23 個縮寫，包含 ETH、UBC、HKUST、TUM、TU、IIT、RMIT、UQ、UGA 等。  
**Fix L**（`rank_parser.c`）：新增 `safe_parse_int()`，使用 `strtol` 搭配 `ERANGE` 與合理上限檢查，所有排名解析統一經此函式處理。

### 5.4 新增測試

`src/tests/test_regression4.c`（85 項）：

| 組別 | 項數 | 說明 |
|------|------|------|
| I — rank 大小寫 | 13 | `TOP` / `RANK` / `top` / `rank` / 無空格變體 |
| L — 整數溢位 | 8 | 超大值、`INT_MAX+1`、上限邊界、負數 |
| J — 國家別名 | 20 | Korea / Russia / Macao / Czechia / Iran / Vietnam、冪等 |
| K — 縮寫清單 | 20 | ETH / UBC / HKUST / TUM / IIT / RMIT、冪等、回歸 |
| 整合 | 15 | 五筆跨弱點 pipeline、CSV 輸出驗證 |
| 邊界 | 9 | 溢位 + prefix 組合、`NULL`、前序 Session 回歸 |

### 5.5 全套測試結果（Session 4 後）

| 套件 | 項數 | 結果 |
|------|------|------|
| `test_normalizer` | 17 | ✅ |
| `test_extreme` | 139 | ✅ |
| `test_scale` | 31 | ✅ |
| `test_weakness` | 43 | ✅ |
| `test_regression2` | 60 | ✅ |
| `test_regression3` | 71 | ✅ |
| `test_regression4` | 85 | ✅ |
| **合計** | **446** | ✅ **446/446** |

---

## 六、最終累計測試結果

| 測試套件 | 通過 / 總計 |
|---------|-----------|
| `test_normalizer` | 17 / 17 |
| `test_extreme` | 139 / 139 |
| `test_scale` | 31 / 31 |
| `test_weakness` | 43 / 43 |
| `test_regression2` | 60 / 60 |
| `test_regression3` | 71 / 71 |
| `test_regression4` | 85 / 85 |
| **合計** | **446 / 446** |

### 跨四輪修正彙總

| 修正編號 | 元件 | 說明 |
|---------|------|------|
| Fix 1 | `rank_parser` | 支援 `=N` 格式（Case 4） |
| Fix 2 | `name_normalizer` | `/` 後字母大寫 |
| Fix 3 | `name_normalizer` | 新增 6 個小寫連接詞（`in/at/to/by/a/an`） |
| Fix 4 | `country_normalizer` | 新增 28 個國家別名條目 |
| Fix 5 | `rank_parser` | 支援 `#N` 格式（Case 5） |
| Fix 6 | `rank_parser` | 拒絕負數排名 |
| Fix E | `country_normalizer` | 修正連字號國家名稱被黏合 |
| Fix F | `utils` | 補齊 title case 小寫連接詞清單 |
| Fix G | `name_normalizer` | 移除 `Tech -> Technology` 誤展開 |
| Fix H | `csv_writer` | 修正 unresolved rank 的 CSV 欄位數 |
| Fix I | `rank_parser` | Top / Rank 前綴大小寫不敏感 |
| Fix J | `country_normalizer` | 補齊常見資料集國家別名 |
| Fix K | `name_normalizer` / `utils` | 補齊大學縮寫清單 |
| Fix L | `rank_parser` | 改用 `strtol` 防止整數溢位 |

---

## 七、已知限制

1. **W5：score `-1.0` 哨兵碰撞**：輸入 `-1.0` 與「無資料」哨兵值仍無法區分。
2. **`csv_writer` 未驗證倒置排名**：`rank_min > rank_max` 仍屬設計缺口。
3. **CLI 仍使用固定 sample 路徑**：目前較偏本地示範與批次測試，非通用命令列工具。

---

## 八、檔案變更清單

| 檔案 | 狀態 | 說明 |
|------|------|------|
| `c_engine/src/rank_parser.c` | 修改 | `=N`、`#N`、負數拒絕、大小寫前綴、`strtol` 溢位保護 |
| `c_engine/src/name_normalizer.c` | 修改 | `/` 後大寫、連接詞調整、縮寫清單擴充、移除 `Tech` 誤展開 |
| `c_engine/src/country_normalizer.c` | 修改 | 國家別名表擴充、連字號名稱修正 |
| `c_engine/src/utils.c` | 修改 | title case 連接詞與縮寫清單同步 |
| `c_engine/src/csv_writer.c` | 修改 | unresolved rank 的 CSV 欄位數修正 |
| `c_engine/src/tests/test_weakness.c` | 新增 / 更新 | Session 1 弱點回歸 |
| `c_engine/src/tests/test_regression2.c` | 新增 | Session 2 回歸測試 |
| `c_engine/src/tests/test_regression3.c` | 新增 | Session 3 回歸測試 |
| `c_engine/src/tests/test_regression4.c` | 新增 | Session 4 回歸測試 |
| `c_engine/Makefile` | 修改 | 納入 `test_weakness`、`test_regression2/3/4` 與 `test_all` |
| `apply_session2_patches.sh` | 新增（歷史） | Session 2 補丁套用輔助腳本 |
| `apply_session4_patches.py` | 新增（歷史） | Session 4 補丁套用輔助腳本 |

---

## 九、驗證步驟

```bash
cd /Users/test/Desktop/crawlernest-normalization/c_engine
make clean
make test_all
```

預期結果：`446 / 446` 全數通過。

---

*本文件已整合原 `test-report.md` 與 `test-record.md` 內容，作為單一測試主報告。*
