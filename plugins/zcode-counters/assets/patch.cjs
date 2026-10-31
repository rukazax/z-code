// zcode-counters: добавляет полосу счётчиков над полем ввода ZCode
// (ходы · шаги · ток/с · Σ токенов · попадание в кэш) — по образцу счётчиков,
// как в DeepSeek Harness.
//
// ZCode имеет ровно две локаля, UI рендерится из out/renderer/index.html.
// Платче: вставляем в index.html самодостаточный <script> — DOM-оверлей,
// который раз в ~0.8 c читает /usage/latest локального демона (127.0.0.1:7717)
// и обновляет строку. Если демона нет — полоса прячется, ошибок нет.
//
// Запуск (как у zcode-ru, через рантайм ZCode):
//   ELECTRON_RUN_AS_NODE=1 ELECTRON_NO_ASAR=1 ZCode.exe patch.js <installDir> <out.asar>
const fs = require('fs');
const path = require('path');
const os = require('os');
const crypto = require('crypto');

const TARGET = '/out/renderer/index.html';

const installDir = path.resolve(process.argv[2] || path.join('C:\\', 'Program Files', 'ZCode'));
const OUT = process.argv[3];
const RES = path.join(installDir, 'resources');
const ASAR = path.join(RES, 'app.asar');

if (!fs.existsSync(ASAR)) {
  console.error('Не найден ' + ASAR);
  process.exit(1);
}
if (!OUT) {
  console.error('Укажите путь для результата: patch.js <installDir> <out.asar>');
  process.exit(1);
}

// ---------- оверлей для index.html ----------
// Сам код оверлея лежит отдельным файлом — так его проще править и проверять.
const OVERLAY_SRC = fs.readFileSync(path.join(__dirname, 'overlay.js'), 'utf8');
const MARK = 'data-zcode-counters';
const OVERLAY = '    <!-- [zcode-counters v5] счётчики в строке Working -->\n    <script>\n'
  + OVERLAY_SRC + '    </script>\n';

// ---------- read asar ----------
const fd = fs.openSync(ASAR, 'r');
const sizeBuf = Buffer.alloc(16);
fs.readSync(fd, sizeBuf, 0, 16, 0);
if (sizeBuf.readUInt32LE(0) !== 4 || sizeBuf.readUInt32LE(8) !== sizeBuf.readUInt32LE(4) - 4) {
  console.error('Неизвестный формат asar-архива; прерываю.');
  process.exit(1);
}
const headerPickleSize = sizeBuf.readUInt32LE(4);
const contentStart = 8 + headerPickleSize;
const jsonLenOrig = sizeBuf.readUInt32LE(12);
const jsonBuf = Buffer.alloc(jsonLenOrig);
fs.readSync(fd, jsonBuf, 0, jsonLenOrig, 16);
const header = JSON.parse(jsonBuf.toString());
const fileSize = fs.fstatSync(fd).size;

function getEntry(relPath) {
  const parts = relPath.split('/').filter(Boolean);
  if (parts.some((p) => p === '.' || p === '..')) throw new Error('bad path');
  let node = header;
  for (const p of parts) {
    if (!node.files || !node.files[p]) return null;
    node = node.files[p];
  }
  return node && node.offset !== undefined ? node : null;
}
function readFile(relPath) {
  const e = getEntry(relPath);
  if (!e) throw new Error('Нет в архиве: ' + relPath);
  const buf = Buffer.alloc(e.size);
  fs.readSync(fd, buf, 0, e.size, contentStart + parseInt(e.offset, 10));
  return buf;
}

const BLOCK = 4194304;
function integrityOf(buf) {
  const blocks = [];
  for (let off = 0; off < buf.length; off += BLOCK) {
    blocks.push(crypto.createHash('sha256').update(buf.subarray(off, Math.min(off + BLOCK, buf.length))).digest('hex'));
  }
  return {
    algorithm: 'SHA256',
    hash: crypto.createHash('sha256').update(buf).digest('hex'),
    blockSize: BLOCK,
    blocks,
  };
}
{
  const stored = getEntry('/package.json').integrity;
  const mine = integrityOf(readFile('/package.json'));
  if (mine.hash !== stored.hash) {
    console.error('Контрольные суммы не сошлись — неизвестная структура asar; прерываю.');
    process.exit(1);
  }
}

const entry = getEntry(TARGET);
if (!entry) { console.error('Не найден ' + TARGET); process.exit(1); }

const html = readFile(TARGET).toString('utf8');
if (!/<\/body>/i.test(html)) { console.error('В index.html нет </body>; прерываю.'); process.exit(1); }

// идемпотентность: старые версии блока (v1/v2) вырезаем и ставим актуальную
const cleaned = html.replace(/<!-- \[zcode-counters[^\n]*-->\s*<script>[\s\S]*?<\/script>\n?/g, '');
const patched = cleaned.replace(/<\/body>/i, `${OVERLAY}</body>`);

// ---------- rebuild asar ----------
const changed = new Map([[TARGET, Buffer.from(patched, 'utf8')]]);
let appendOffset = fileSize - contentStart;
for (const [rel, buf] of changed) {
  const e = getEntry(rel);
  e.size = buf.length;
  e.offset = String(appendOffset);
  e.integrity = integrityOf(buf);
  appendOffset += buf.length;
}
let headerJson = JSON.stringify(header);
const headerBudget = headerPickleSize - 8;
let natural = Buffer.byteLength(headerJson, 'utf8');
if (natural > headerBudget) {
  const rem = (4 + natural) % 4;
  if (rem) headerJson = headerJson.padEnd(natural + (4 - rem), ' ');
  console.log('Заголовок вырос — полная перезапись архива.');
} else {
  headerJson = headerJson.padEnd(headerBudget, ' ');
}
const jsonLen = Buffer.byteLength(headerJson, 'utf8');
if ((4 + jsonLen) % 4 !== 0) {
  console.error('Не смог выровнять заголовок; прерываю.');
  process.exit(1);
}
JSON.parse(headerJson);
function mkdirOut(p) { fs.mkdirSync(path.dirname(p), { recursive: true }); return p; }

const prefix = Buffer.alloc(16);
prefix.writeUInt32LE(4, 0);
prefix.writeUInt32LE(8 + jsonLen, 4);
prefix.writeUInt32LE(4 + jsonLen, 8);
prefix.writeUInt32LE(jsonLen, 12);

const out = fs.openSync(mkdirOut(OUT), 'w');
fs.writeSync(out, prefix, 0, 16);
fs.writeSync(out, Buffer.from(headerJson, 'utf8'), 0, jsonLen);
{
  const CP = 8 * 1024 * 1024;
  const cpBuf = Buffer.alloc(CP);
  let pos = contentStart;
  while (pos < fileSize) {
    const n = fs.readSync(fd, cpBuf, 0, Math.min(CP, fileSize - pos), pos);
    fs.writeSync(out, cpBuf, 0, n);
    pos += n;
  }
}
for (const [, buf] of changed) fs.writeSync(out, buf, 0, buf.length);
fs.closeSync(out);
fs.closeSync(fd);

console.log('Готово: патченный архив с полосой счётчиков записан в ' + OUT);
process.exit(0);


