// Урезает NotoSans до нужных символов (латиница, кириллица, пунктуация, ₽, стрелки):
// полный шрифт ~560 КБ на начертание, nginx его не сжимает — тормозит первый запуск.
// Исходники: tool/fonts_src/*.ttf → результат: assets/fonts/*.ttf
//
// Запуск:
//   npm i --no-save --prefix "$env:TEMP\fontsubset" subset-font
//   $env:NODE_PATH="$env:TEMP\fontsubset\node_modules"; node tool/subset_fonts.js
const fs = require('fs');
const path = require('path');
const subsetFont = require('subset-font');

const ranges = [
  [0x0020, 0x007e], // Basic Latin
  [0x00a0, 0x017f], // Latin-1, Latin Extended-A
  [0x0300, 0x036f], // комбинируемые знаки (ударения)
  [0x0400, 0x052f], // кириллица + дополнение (укр., каз. и др.)
  [0x2000, 0x206f], // пунктуация: тире, кавычки, многоточие
  [0x20a0, 0x20cf], // валюты, в т.ч. ₽
  [0x2100, 0x214f], // №, ™
  [0x2190, 0x21ff], // стрелки
  [0x2212, 0x2212], // минус
  [0x2264, 0x2265], // ≤ ≥
];

let text = '';
for (const [from, to] of ranges) {
  for (let c = from; c <= to; c++) text += String.fromCodePoint(c);
}

const walk = (dir) => fs.readdirSync(dir, { withFileTypes: true }).flatMap((d) =>
  d.isDirectory() ? walk(path.join(dir, d.name)) : d.name.endsWith('.dart') ? [path.join(dir, d.name)] : []);
for (const file of walk('lib')) text += fs.readFileSync(file, 'utf8');

(async () => {
  for (const name of ['NotoSans-Regular.ttf', 'NotoSans-Bold.ttf']) {
    const source = fs.readFileSync(path.join('tool', 'fonts_src', name));
    const result = await subsetFont(source, text, { targetFormat: 'truetype' });
    fs.writeFileSync(path.join('assets', 'fonts', name), result);
    console.log(`${name}: ${Math.round(source.length / 1024)} KB -> ${Math.round(result.length / 1024)} KB`);
  }
})();
