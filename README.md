# crawlernest-normalization

數據規規化引擎，用於標準化大學名稱、國家及成績分數。

## 模組說明
- **c_engine**: 使用 C 語言編寫的高效能規規化引擎。
  - `src/`: 核心實作代碼。
  - `include/`: 標頭檔。
  - `Makefile`: 編譯腳本。
  - `data/samples/`: 存放原始與規規化後的 CSV 檔案。

## 使用說明 (C 引擎)

此模組提供高效能的 CLI 工具，用於批次處理爬蟲產出的 CSV 數據。

### 1. 編譯引擎
在 `c_engine` 目錄下執行以下指令：
```bash
cd c_engine
make
```

### 2. 準備數據
將爬蟲產出的 CSV 檔案（例如 `universities_world.csv`）複製到範例數據目錄：
```bash
cp ../../universities_world.csv data/samples/raw_universities.csv
```

### 3. 執行規規化
執行編譯好的程式並按照選單操作：
```bash
make run
```
**選單操作步驟：**
1.  輸入 `1`：載入 CSV 資料。
2.  輸入 `3`：執行完整正規化流程（清洗名稱、解析排名區間、提取分數）。
3.  輸入 `4`：預覽規規化後的結果。
4.  輸入 `5`：將結果匯出成新的 `.csv` 檔。

### 4. 查看結果
規規化後的檔案預設儲存在：
`data/samples/normalized_universities.csv`

## 測試指引

以下是在本機快速驗證 normalization 引擎的建議流程。

### 1. 執行單元測試
在 `c_engine` 目錄下執行：
```bash
cd c_engine
make test
```

預期結果：
- 顯示 `Passed: 17 / 17`
- 顯示 `All tests passed.`

此測試會驗證：
- 大學名稱正規化
- 國家名稱正規化
- 排名區間解析
- 分數解析
- CSV 讀寫與 escaping

### 2. 執行互動式整體測試
先確認輸入檔存在：
```bash
ls data/samples/raw_universities.csv
```

再執行：
```bash
make run
```

建議依序輸入以下選單選項：
1. `1`：載入 CSV 資料
2. `3`：執行完整正規化流程
3. `4`：預覽正規化後資料
4. `5`：匯出正規化結果到 CSV
5. `0`：離開程式

### 3. 一鍵快速驗證
如果你想快速驗證 sample data 能否正常跑完整流程，可以在 `c_engine` 目錄下執行：
```bash
printf '1\n3\n5\n0\n' | ./build/clawer_normalizer
```

如果尚未編譯，先執行：
```bash
make
```

### 4. 檢查輸出結果
匯出完成後，可直接查看結果：
```bash
sed -n '1,20p' data/samples/normalized_universities.csv
```

目前 sample 的預期輸出格式如下：
```csv
University,Country,Rank Min,Rank Max,Overall Score
University of California Berkeley (Ucb),United States,12,14,91.70
```

### 5. 常見問題
- 如果 `make test` 失敗，先執行 `make clean && make test` 重新編譯。
- 如果顯示 `載入失敗，請確認 CSV 檔案是否存在。`，請確認 `data/samples/raw_universities.csv` 路徑正確。
- 如果 CSV header 欄位數或欄名不符合預期，reader 會拒絕載入。
- 若要改用自己的資料，可將你的 CSV 覆蓋到 `data/samples/raw_universities.csv` 後重新執行。

---
*註：規規化流程會移除多餘標點符號、統一轉換小寫，並將排名區間（如 101-150）解析為數值格式。*

## License

This project is licensed under the Apache License 2.0.
