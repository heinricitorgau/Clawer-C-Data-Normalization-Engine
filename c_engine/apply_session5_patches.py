#!/usr/bin/env python3
"""
apply_session5_patches.py

Session 5 パッチ適用スクリプト
────────────────────────────────────────────────────────────
session 5 で修正されたファイルを .new ファイルから正式ファイルへ移動する。

macFUSEマウントのEDEADLKにより既存ファイルをLinuxサンドボックスから直接上書きできないため、
.new ファイル経由でパッチを適用する。

修正対象:
  - src/tests/test_extreme.c  （Fix P/Q に対応した期待値更新）

実行方法: python3 apply_session5_patches.py
"""

import os
import shutil

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

patches = [
    ("src/tests/test_extreme.c.new", "src/tests/test_extreme.c"),
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
