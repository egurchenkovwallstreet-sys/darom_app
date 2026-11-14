from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "lib"

REPLACEMENTS = [
    ("AppColors.textPrimary.withOpacity(0.85)", "AppColors.surface.withOpacity(0.92)"),
    ("AppColors.textPrimary.withOpacity(0.9)", "AppColors.surface.withOpacity(0.92)"),
    ("AppColors.textPrimary.withOpacity(0.92)", "AppColors.surface.withOpacity(0.94)"),
    ("AppColors.textPrimary.withOpacity(0.95)", "AppColors.surface.withOpacity(0.95)"),
    ("fillColor: AppColors.textPrimary", "fillColor: AppColors.surface"),
    ("const Color(0xFFFFFFFF)", "AppColors.textPrimary"),
]

SKIP = {"theme/app_colors.dart"}


def main() -> None:
    for path in ROOT.rglob("*.dart"):
        rel = str(path.relative_to(ROOT)).replace("\\", "/")
        if rel in SKIP:
            continue
        text = path.read_text(encoding="utf-8")
        new = text
        for a, b in REPLACEMENTS:
            new = new.replace(a, b)
        if new != text:
            path.write_text(new, encoding="utf-8")
            print("fixed", rel)


if __name__ == "__main__":
    main()