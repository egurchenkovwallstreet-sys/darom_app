"""Replace legacy white body text with AppColors on light UI (excludes admin screens)."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"

SKIP_FILES = {
    "theme/app_colors.dart",
    "theme/darom_decorations.dart",
    "main.dart",
}

SKIP_PREFIXES = ("screens/admin_",)

# Whole-file replaces (order matters).
REPLACEMENTS = [
    ("const TextStyle(color: Color(0xFFFFFFFF)", "const TextStyle(color: AppColors.textPrimary"),
    ("TextStyle(color: Color(0xFFFFFFFF)", "TextStyle(color: AppColors.textPrimary"),
    ("color: Color(0xFFFFFFFF),", "color: AppColors.textPrimary,"),
    ("color: Color(0xFFFFFFFF)", "color: AppColors.textPrimary"),
    ("style: const TextStyle(color: Colors.white)", "style: const TextStyle(color: AppColors.textPrimary)"),
    ("style: TextStyle(color: Colors.white)", "style: TextStyle(color: AppColors.textPrimary)"),
    ("TextStyle(color: Colors.white,", "TextStyle(color: AppColors.textPrimary,"),
    ("const TextStyle(color: Colors.white,", "const TextStyle(color: AppColors.textPrimary,"),
    ("TextStyle(color: Colors.white54", "TextStyle(color: AppColors.textSecondary"),
    ("const TextStyle(color: Colors.white54", "const TextStyle(color: AppColors.textSecondary"),
    ("TextStyle(color: Colors.white70", "TextStyle(color: AppColors.textSecondary"),
    ("const TextStyle(color: Colors.white70", "const TextStyle(color: AppColors.textSecondary"),
    ("TextStyle(color: Colors.white38", "TextStyle(color: AppColors.textSecondary.withOpacity(0.75)"),
    ("const TextStyle(color: Colors.white38", "const TextStyle(color: AppColors.textSecondary.withOpacity(0.75)"),
    ("color: Colors.white.withOpacity(0.9)", "color: AppColors.textSecondary"),
    ("color: Colors.white.withOpacity(0.85)", "color: AppColors.textSecondary"),
    ("color: Colors.white.withOpacity(0.8)", "color: AppColors.textSecondary"),
    ("color: Colors.white.withOpacity(0.75)", "color: AppColors.textSecondary"),
    ("color: Colors.white.withOpacity(0.6)", "color: AppColors.textSecondary.withOpacity(0.9)"),
    ("color: Colors.white.withOpacity(0.5)", "color: AppColors.textSecondary.withOpacity(0.85)"),
    ("color: Colors.white.withOpacity(0.45)", "color: AppColors.textSecondary.withOpacity(0.8)"),
    ("color: Colors.white,", "color: AppColors.textPrimary,"),
    ("color: Colors.white\n", "color: AppColors.textPrimary\n"),
]


def ensure_import(text: str, path: Path) -> str:
    if "AppColors." not in text:
        return text
    if "app_colors.dart" in text:
        return text
    rel = path.relative_to(ROOT)
    depth = len(rel.parts) - 1
    prefix = "../" * depth if depth else ""
    imp_pkg = "import 'package:darom_app/theme/app_colors.dart';"
    imp_rel = f"import '{prefix}theme/app_colors.dart';"
    marker = "import 'package:flutter/material.dart';"
    if marker in text:
        use = imp_pkg if depth == 0 or depth > 2 else imp_rel
        if "widgets/" in str(rel) or "screens/" in str(rel):
            use = imp_pkg if "package:darom_app" in text else imp_rel
        return text.replace(marker, f"{marker}\n{use}", 1)
    return f"{imp_pkg}\n{text}"


def should_skip(rel: str) -> bool:
    if rel in SKIP_FILES:
        return True
    return any(rel.startswith(p) for p in SKIP_PREFIXES)


def main() -> None:
    updated = 0
    for path in sorted(ROOT.rglob("*.dart")):
        rel = path.relative_to(ROOT).as_posix()
        if should_skip(rel) or rel.startswith("l10n/"):
            continue
        text = path.read_text(encoding="utf-8")
        original = text
        for old, new in REPLACEMENTS:
            text = text.replace(old, new)
        if text != original:
            text = ensure_import(text, path)
            path.write_text(text, encoding="utf-8")
            updated += 1
            print("updated", rel)
    print(f"done, {updated} files")


if __name__ == "__main__":
    main()