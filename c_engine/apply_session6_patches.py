#!/usr/bin/env python3
"""
apply_session6_patches.py

Session 6 パッチ適用スクリプト
────────────────────────────────────────────────────────────
macFUSEマウントのEDEADLKにより既存ファイルをLinuxサンドボックスから
直接上書きできないため、.new ファイル経由でパッチを適用する。

修正対象:
  - src/score_parser.c  （Fix S: 前導小數點 ".5" → 0.5）

実行方法: python3 apply_session6_patches.py
"""

import os
import shutil

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

patches = [
    ("src/score_parser.c.new", "src/score_parser.c"),
]

for src_rel, dst_rel in patches:
    src = os.path.join(SCRIPT_DIR, src_rel)
    dst = os.path.join(SCRIPT_DIR, dst_rel)

    if not os.path.exists(src):
        print(f"[SKIP] 元ファイルが存在しません: {src_rel}")
        continue

    try:
        shutil.move(src, dst)
        print(f"[OK]   {src_rel} -> {dst_rel}")
    except Exception as e:
        print(f"[FAIL] {src_rel}: {e}")

print("パッチ適用完了。")
