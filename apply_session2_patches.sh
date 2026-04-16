#!/bin/bash
# apply_session2_patches.sh
#
# 此腳本用於將 Session 2 的修正套用至因 Linux 沙箱 POSIX 鎖（EDEADLK）
# 而無法直接從沙箱覆寫的檔案。
#
# 請在 macOS 終端機（您的本機電腦）中執行此腳本：
#
#   cd ~/Desktop/crawlernest-normalization
#   bash apply_session2_patches.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/c_engine/src"

echo "=== 套用 Session 2 修正 ==="

# name_normalizer.c：新增 6 個小寫連接詞（in/at/to/by/a/an）
if [ -f "$SRC/name_normalizer.c.new" ]; then
    mv "$SRC/name_normalizer.c.new" "$SRC/name_normalizer.c"
    echo "[OK] name_normalizer.c 已更新（新增 6 個小寫連接詞：in/at/to/by/a/an）"
else
    echo "[SKIP] name_normalizer.c.new 不存在，跳過"
fi

# country_normalizer.c：新增 28 個國家別名條目
if [ -f "$SRC/country_normalizer.c.new" ]; then
    mv "$SRC/country_normalizer.c.new" "$SRC/country_normalizer.c"
    echo "[OK] country_normalizer.c 已更新（新增 DPRK、UAE、MY、倒裝韓國等別名）"
else
    echo "[SKIP] country_normalizer.c.new 不存在，跳過"
fi

# test-report.md：更新為完整兩輪報告
if [ -f "$SCRIPT_DIR/test-report.md.new" ]; then
    mv "$SCRIPT_DIR/test-report.md.new" "$SCRIPT_DIR/test-report.md"
    echo "[OK] test-report.md 已更新（Session 2 完整報告，290/290）"
else
    echo "[SKIP] test-report.md.new 不存在，跳過"
fi

echo ""
echo "修正完成。請執行以下指令驗證："
echo "  cd c_engine && make clean && make test_all"
