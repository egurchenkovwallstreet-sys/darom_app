"""One-off visual palette migration for lib/**/*.dart (run from project root)."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"

REPLACEMENTS = [
    ("const Color(0xFF00BFFF)", "AppColors.accent"),
    ("Color(0xFF00BFFF)", "AppColors.accent"),
    ("const Color(0xFF008C8C)", "AppColors.accentDark"),
    ("Color(0xFF008C8C)", "AppColors.accentDark"),
    ("const Color(0xFF80DEEA)", "AppColors.textSecondary"),
    ("Color(0xFF80DEEA)", "AppColors.textSecondary"),
    ("const Color(0xFF001F3F)", "AppColors.textPrimary"),
    ("Color(0xFF001F3F)", "AppColors.textPrimary"),
    ("const Color(0xFFFF5722)", "AppColors.danger"),
    ("Color(0xFFFF5722)", "AppColors.danger"),
    ("const Color(0xFF2196F3)", "AppColors.accent"),
    ("Color(0xFF2196F3)", "AppColors.accent"),
]

SKIP = {"theme/app_colors.dart", "theme/darom_decorations.dart"}


def needs_import(text: str) -> bool:
    return "AppColors." in text and "theme/app_colors.dart" not in text


def add_import(text: str) -> str:
    if not needs_import(text):
        return text
    marker = "import 'package:flutter/material.dart';"
    imp = "import '../theme/app_colors.dart';"
    if "package:darom_app/theme/app_colors.dart" in text or imp in text:
        return text
    if marker in text:
        return text.replace(marker, f"{marker}\n\nimport 'package:darom_app/theme/app_colors.dart';", 1)
    return f"import 'package:darom_app/theme/app_colors.dart';\n{text}"


def main() -> None:
    for path in ROOT.rglob("*.dart"):
        rel = str(path.relative_to(ROOT)).replace("\\", "/")
        if rel in SKIP or rel.startswith("l10n/"):
            continue
        text = path.read_text(encoding="utf-8")
        original = text
        for old, new in REPLACEMENTS:
            text = text.replace(old, new)
        if text != original:
            if "AppColors." in text and "app_colors.dart" not in text:
                marker = "import 'package:flutter/material.dart';"
                if marker in text:
                    text = text.replace(
                        marker,
                        f"{marker}\nimport 'package:darom_app/theme/app_colors.dart';",
                        1,
                    )
            path.write_text(text, encoding="utf-8")
            print("updated", rel)


if __name__ == "__main__":
    main()