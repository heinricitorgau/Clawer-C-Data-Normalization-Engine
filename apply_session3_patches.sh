#!/bin/bash
# apply_session3_patches.sh
#
# 此腳本用於將 Session 3 的修正套用至因 Linux 沙箱 POSIX 鎖（EDEADLK）
# 而無法直接從沙箱覆寫的檔案。
#
# 請在 macOS 終端機（您的本機電腦）中執行此腳本：
#
#   cd ~/Desktop/crawlernest-normalization
#   bash apply_session3_patches.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/c_engine/src"

echo "=== 套用 Session 3 修正 ==="

# csv_writer.c：Fix H — rank_min < 0 時輸出正確的 3 個逗號（5 欄格式）
if [ -f "$SRC/csv_writer.c.new" ]; then
    mv "$SRC/csv_writer.c.new" "$SRC/csv_writer.c"
    echo "[OK] csv_writer.c 已更新（Fix H：rank 未解析時輸出 ',,,', 保持 5 欄格式）"
else
    echo "[SKIP] csv_writer.c.new 不存在，跳過"
fi

# test_extreme.c：更新 4 項與 Fix G 衝突的過時測試預期值
if [ -f "$SRC/tests/test_extreme.c.new" ]; then
    mv "$SRC/tests/test_extreme.c.new" "$SRC/tests/test_extreme.c"
    echo "[OK] test_extreme.c 已更新（修正 4 項 Tech→Technology 過時預期值）"
else
    echo "[SKIP] test_extreme.c.new 不存在，跳過"
fi

echo ""
echo "修正完成。請執行以下指令驗證（預期 361/361 全部通過）："
echo "  cd c_engine && make clean && make test_all"
