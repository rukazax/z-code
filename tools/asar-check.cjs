// Быстрая проверка app.asar: версия ZCode и наличие наших патчей.
// Запуск: node tools/asar-check.cjs "C:\Program Files\ZCode\resources\app.asar"
const fs = require('node:fs');

const ASAR = process.argv[2];
if (!ASAR || !fs.existsSync(ASAR)) { console.error('нет файла asar'); process.exit(2); }

const fd = fs.openSync(ASAR, 'r');
const b = Buffer.alloc(16);
fs.readSync(fd, b, 0, 16, 0);
const contentStart = 8 + b.readUInt32LE(4);
const jsonLen = b.readUInt32LE(12);
const jb = Buffer.alloc(jsonLen);
fs.readSync(fd, jb, 0, jsonLen, 16);
const header = JSON.parse(jb.toString());

function entry(rel) {
  let n = header;
  for (const p of rel.split('/').filter(Boolean)) {
    if (!n.files || !n.files[p]) return null;
    n = n.files[p];
  }
  return n && n.offset !== undefined ? n : null;
}
function read(rel) {
  const e = entry(rel);
  if (!e) return null;
  const buf = Buffer.alloc(e.size);
  fs.readSync(fd, buf, 0, e.size, contentStart + parseInt(e.offset, 10));
  return buf.toString('utf8');
}

const pkg = JSON.parse(read('package.json') || '{}');
const html = read('out/renderer/index.html') || '';
let ru = false;
const assets = header.files?.out?.files?.renderer?.files?.assets?.files || {};
const intl = Object.keys(assets).find((n) => /^IntlProvider-.*\.js$/.test(n));
if (intl) {
  const src = read('out/renderer/assets/' + intl) || '';
  ru = (src.match(/[А-Яа-яЁё]/g) || []).length > 1000;
}

console.log(JSON.stringify({
  version: pkg.version || null,
  ru,
  counters: html.includes('zcode-counters'),
  limits: html.includes('лимиты'),
}, null, 1));
fs.closeSync(fd);
