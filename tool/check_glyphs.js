// Находит символы в lib/**/*.dart, которых нет в assets/fonts/NotoSans-Regular.ttf.
// Такие символы заставляют Flutter Web докачивать шрифты с fonts.gstatic.com (медленно на iPhone в РФ).
const fs = require('fs');
const path = require('path');

const font = fs.readFileSync('assets/fonts/NotoSans-Regular.ttf');
const numTables = font.readUInt16BE(4);
let cmap = 0;
for (let i = 0; i < numTables; i++) {
  if (font.toString('ascii', 12 + i * 16, 16 + i * 16) === 'cmap') cmap = font.readUInt32BE(12 + i * 16 + 8);
}
let sub = -1;
for (let i = 0; i < font.readUInt16BE(cmap + 2); i++) {
  const p = font.readUInt16BE(cmap + 4 + i * 8);
  const e = font.readUInt16BE(cmap + 6 + i * 8);
  const o = font.readUInt32BE(cmap + 8 + i * 8);
  if (p === 3 && e === 1 && font.readUInt16BE(cmap + o) === 4) sub = cmap + o;
}
const segs = font.readUInt16BE(sub + 6) / 2;
const ends = sub + 14;
const starts = ends + segs * 2 + 2;
const has = (c) => {
  if (c > 0xffff) return false;
  for (let i = 0; i < segs; i++) {
    if (c <= font.readUInt16BE(ends + i * 2)) return c >= font.readUInt16BE(starts + i * 2);
  }
  return false;
};

const walk = (dir) => fs.readdirSync(dir, { withFileTypes: true }).flatMap((d) =>
  d.isDirectory() ? walk(path.join(dir, d.name)) : d.name.endsWith('.dart') ? [path.join(dir, d.name)] : []);

for (const file of walk('lib')) {
  fs.readFileSync(file, 'utf8').split('\n').forEach((line, i) => {
    const code = line.replace(/^\s*\/\/.*$/, '').replace(/\s\/\/\s.*$/, '');
    const bad = [...code].filter((ch) => ch.codePointAt(0) > 127 && ch !== '\uFEFF' && !has(ch.codePointAt(0)));
    if (bad.length) console.log(`${file}:${i + 1}: ${[...new Set(bad)].join(' ')}`);
  });
}
