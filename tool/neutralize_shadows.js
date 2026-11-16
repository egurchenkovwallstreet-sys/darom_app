// Заменяет все цветные boxShadow в lib/ на DaromDecorations.cardShadow (0 4px 20px rgba(0,0,0,0.04)).
// Запуск: node tool/neutralize_shadows.js lib
const fs = require('fs');
const path = require('path');

const root = process.argv[2];

function walk(dir, out) {
  for (const name of fs.readdirSync(dir)) {
    const p = path.join(dir, name);
    if (fs.statSync(p).isDirectory()) walk(p, out);
    else if (name.endsWith('.dart')) out.push(p);
  }
  return out;
}

function exprEnd(src, start) {
  let depth = 0;
  let inStr = null;
  for (let i = start; i < src.length; i++) {
    const c = src[i];
    if (inStr) {
      if (c === '\\') { i++; continue; }
      if (c === inStr) inStr = null;
      continue;
    }
    if (c === "'" || c === '"') { inStr = c; continue; }
    if (c === '(' || c === '[' || c === '{') depth++;
    else if (c === ')' || c === ']' || c === '}') {
      if (depth === 0) return i;
      depth--;
    } else if (c === ',' && depth === 0) return i;
  }
  return -1;
}

let changed = 0;
for (const file of walk(root, [])) {
  if (file.endsWith('darom_decorations.dart')) continue;
  const before = fs.readFileSync(file, 'utf8');
  const re = /boxShadow:\s*/g;
  let out = '';
  let last = 0;
  let m;
  while ((m = re.exec(before)) !== null) {
    const valStart = m.index + m[0].length;
    const end = exprEnd(before, valStart);
    if (end < 0) continue;
    const value = before.slice(valStart, end);
    if (!/BoxShadow\(/.test(value)) continue;
    out += before.slice(last, valStart) + 'DaromDecorations.cardShadow';
    last = end;
    re.lastIndex = end;
  }
  let src = out + before.slice(last);
  if (src === before) continue;
  if (!/darom_decorations\.dart'/.test(src)) {
    const idx = src.indexOf("import 'package:flutter/material.dart';");
    const line = "import 'package:darom_app/theme/darom_decorations.dart';\n";
    src = idx >= 0 ? src.slice(0, idx) + line + src.slice(idx) : line + src;
  }
  fs.writeFileSync(file, src);
  changed++;
  console.log('updated', path.relative(root, file));
}
console.log('files changed:', changed);
