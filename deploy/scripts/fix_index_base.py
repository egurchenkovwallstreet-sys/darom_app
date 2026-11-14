from pathlib import Path

p = Path("/var/www/darom/index.html")
text = p.read_text(encoding="utf-8")
text = text.replace('<base href="$FLUTTER_BASE_HREF">', '<base href="/">')
p.write_text(text, encoding="utf-8")
print("OK:", p, "base=", "<base href=\"/\">" in text)