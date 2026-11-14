"""One-off migration: legacy neon blues → AppColors tokens."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"

REPLACEMENTS = [
    (r"\bconst Color\(0xFF00BFFF\)", "AppColors.accent"),
    (r"\bColor\(0xFF00BFFF\)", "AppColors.accent"),
    (r"\bconst Color\(0xFF008C8C\)", "AppColors.accentDark"),
    (r"\bColor\(0xFF008C8C\)", "AppColors.accentDark"),
    (r"\bconst Color\(0xFF80DEEA\)", "AppColors.textSecondary"),
    (r"\bColor\(0xFF80DEEA\)", "AppColors.textSecondary"),
    (r"\bconst Color\(0xFFFF5722\)", "AppColors.danger"),
    (r"\bColor\(0xFFFF5722\)", "AppColors.danger"),
    (r"\bconst Color\(0xFF2196F3\)", "AppColors.accent"),
    (r"\bColor\(0xFF2196F3\)", "AppColors.accent"),
    (r"color: const Color\(0xFFFFFFFF\)", "color: AppColors.textPrimary"),
    (r"color: Color\(0xFFFFFFFF\)", "color: AppColors.textPrimary"),
    (r"fillColor: const Color\(0xFF001F3F\)", "fillColor: AppColors.surface"),
    (r"fillColor: Color\(0xFF001F3F\)", "fillColor: AppColors.surface"),
    (
        r"color: const Color\(0xFF001F3F\)\.withOpacity",
        "color: AppColors.surface.withOpacity",
    ),
    (
        r"color: Color\(0xFF001F3F\)\.withOpacity",
        "color: AppColors.surface.withOpacity",
    ),
    (r"const Color\(0xFF001F3F\)\.withOpacity", "AppColors.textSecondary.withOpacity"),
    (r"Color\(0xFF001F3F\)\.withOpacity", "AppColors.textSecondary.withOpacity"),
]

SKIP = {"app_colors.dart", "migrate_ui_colors.py"}


def import_for(path: Path) -> str:
    rel = path.relative_to(ROOT)
    depth = len(rel.parts) - 1
    prefix = "/".join([".."] * depth)
    if depth == 0:
        return "import 'theme/app_colors.dart';\n"
    return f"import '{prefix}/theme/app_colors.dart';\n"


def ensure_import(text: str, path: Path) -> str:
    imp = import_for(path)
    if imp.strip() in text or "theme/app_colors.dart" in text:
        return text
    anchor = "import 'package:flutter/material.dart';\n"
    if anchor in text:
        return text.replace(anchor, anchor + imp, 1)
    anchor = 'import "package:flutter/material.dart";\n'
    if anchor in text:
        return text.replace(anchor, anchor + imp, 1)
    return imp + text


def main() -> None:
    changed = 0
    for path in ROOT.rglob("*.dart"):
        if path.name in SKIP:
            continue
        text = path.read_text(encoding="utf-8")
        original = text
        for pattern, repl in REPLACEMENTS:
            text = re.sub(pattern, repl, text)
        if text == original:
            continue
        if "AppColors." in text:
            text = ensure_import(text, path)
        path.write_text(text, encoding="utf-8")
        changed += 1
        print(path.relative_to(ROOT.parent))
    print(f"Updated {changed} files")


if __name__ == "__main__":
    main()