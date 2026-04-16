#!/bin/bash
# git_commit_instructions.sh
#
# 請在您的 Mac 終端機中執行此腳本，以完成 Session 2 的 git 提交與 PR 建立。
#
# 前置條件：請先執行 apply_session2_patches.sh 套用受鎖定檔案的修正。
#
# 使用方式：
#   cd ~/Desktop/crawlernest-normalization
#   bash git_commit_instructions.sh

set -e

echo "=== Session 2 Git Commit 流程 ==="
echo ""

# 切換到專案目錄
cd "$(dirname "$0")"

# 設定 git 作者資訊
git config user.email "ek2412045@gmail.com"
git config user.name "高恩在"

# 建立新分支
git checkout -b feat/regression2-fixes
echo "[OK] 已建立分支 feat/regression2-fixes"

# 暫存所有修改
git add c_engine/src/rank_parser.c
git add c_engine/src/name_normalizer.c
git add c_engine/src/country_normalizer.c
git add c_engine/src/tests/test_weakness.c
git add c_engine/src/tests/test_regression2.c
git add c_engine/Makefile
git add test-report.md
echo "[OK] 已暫存所有修改"

# 建立 commit
git commit -m "$(cat <<'EOF'
feat: Session 2 — 修正四類弱點並新增 60 個回歸測試（290/290 通過）

弱點 A: name_normalizer — 新增 6 個小寫連接詞（in/at/to/by/a/an）
弱點 B: country_normalizer — 新增 28 個國家別名（DPRK/UAE/MY/倒裝韓國等）
弱點 C: rank_parser — 支援 #N 格式（如 "#10" → 10/10）
弱點 D: rank_parser — 拒絕負數排名（"-100" → -1/-1 哨兵值）

測試結果：
- test_normalizer:  17/17
- test_extreme:    139/139
- test_scale:       31/31
- test_weakness:    43/43  (W3 更新：#N 已修正)
- test_regression2: 60/60  (新增，中文標籤)
- 合計:            290/290

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
echo "[OK] Commit 已建立"

echo ""
echo "=== 完成！請執行以下指令推送並建立 PR ==="
echo ""
echo "  git push -u origin feat/regression2-fixes"
echo ""
echo "推送後至 GitHub 建立 Pull Request："
echo "  https://github.com/heinricitorgau/Clawer-C-Data-Normalization-Engine"
echo ""
echo "PR 標題建議："
echo "  feat: Session 2 regression fixes — 290/290 tests passing"
