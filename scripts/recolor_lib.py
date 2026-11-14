#!/usr/bin/env python3
"""Одноразовая замена устаревших HEX на токены AppColors (визуал)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"

REPLACEMENTS = [
    ("const Color(0xFF00BFFF)", "AppColors.accent"),
    ("Color(0xFF00BFFF)", "AppColors.accent"),
    ("const Color(0xFF008C8C)", "AppColors.accentDark"),
    ("Color(0xFF008C8C)", "AppColors.accentDark"),
    ("const Color(0xFF001F3F)", "AppColors.textPrimary"),
    ("Color(0xFF001F3F)", "AppColors.textPrimary"),
    ("const Color(0xFF80DEEA)", "AppColors.textSecondary"),
    ("Color(0xFF80DEEA)", "AppColors.textSecondary"),
    ("const Color(0xFF2196F3)", "AppColors.accent"),
    ("Color(0xFF2196F3)", "AppColors.accent"),
    ("const Color(0xFFFF5722)", "AppColors.danger"),
    ("Color(0xFFFF5722)", "AppColors.danger"),
    ("const Color(0xFF66D9FF)", "AppColors.accent"),
    ("Color(0xFF66D9FF)", "AppColors.accent"),
    ("const Color(0xFF9AE6FF)", "AppColors.accent"),
    ("const Color(0xFF4DB6AC)", "AppColors.accentDark"),
]

SKIP_DIRS = {"generated"}

IMPORT_LINE = "import '../theme/app_colors.dart';\n"
IMPORT_LINE_THEME = "import 'package:darom_app/theme/app_colors.dart';\n"


def needs_import(text: str) -> bool:
    return "AppColors." in text and "app_colors.dart" not in text


def pick_import(path: Path) -> str:
    rel = path.relative_to(ROOT)
    depth = len(rel.parts) - 1
    if depth == 0:
        return "import 'theme/app_colors.dart';\n"
    return "import " + ("../" * depth) + "theme/app_colors.dart';\n"


def main() -> None:
    changed = 0
    for path in ROOT.rglob("*.dart"):
        if any(p in SKIP_DIRS for p in path.parts):
            continue
        if path.name == "app_colors.dart":
            continue
        text = path.read_text(encoding="utf-8")
        original = text
        for old, new in REPLACEMENTS:
            text = text.replace(old, new)
        if text == original:
            continue
        if needs_import(text):
            lines = text.splitlines(keepends=True)
            insert_at = 0
            for i, line in enumerate(lines):
                if line.startswith("import "):
                    insert_at = i + 1
            lines.insert(insert_at, pick_import(path))
            text = "".join(lines)
        path.write_text(text, encoding="utf-8")
        changed += 1
        print(path.relative_to(ROOT.parent))
    print(f"Updated {changed} files")


if __name__ == "__main__":
    main()