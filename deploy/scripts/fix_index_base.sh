#!/bin/bash
set -euo pipefail
INDEX="${1:-/var/www/darom/index.html}"
python3 <<'PY'
from pathlib import Path
p = Path("/var/www/darom/index.html")
text = p.read_text(encoding="utf-8")
text = text.replace('<base href="$FLUTTER_BASE_HREF">', '<base href="/">')
p.write_text(text, encoding="utf-8")
print("fixed", p)
PY