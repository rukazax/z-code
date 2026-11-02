// Аудит целостности app.asar: сверяет SHA-256 каждого файла с integrity в заголовке.
// Запуск: node tools/audit-asar.cjs "C:\Program Files\ZCode\resources\app.asar"
const fs = require('node:fs');
const crypto = require('node:crypto');

const ASAR = process.argv[2];
if (!ASAR || !fs.existsSync(ASAR)) { console.error('нет файла asar'); process.exit(2); }

const fd = fs.openSync(ASAR, 'r');
const b = Buffer.alloc(16);
fs.readSync(fd, b, 0, 16, 0);
const headerPickleSize = b.readUInt32LE(4);
const contentStart = 8 + headerPickleSize;
const jsonLen = b.readUInt32LE(12);
const jb = Buffer.alloc(jsonLen);
fs.readSync(fd, jb, 0, jsonLen, 16);
const header = JSON.parse(jb.toString());
const fileSize = fs.fstatSync(fd).size;

const files = [];
(function walk(node, prefix) {
  for (const [name, child] of Object.entries(node.files || {})) {
    const p = prefix + '/' + name;
    if (child.files) walk(child, p);
    else if (child.offset !== undefined) files.push({ path: p, entry: child });
  }
})(header, '');

let checked = 0, skipped = 0, bad = 0;
const badList = [];
for (const f of files) {
  const e = f.entry;
  if (!e.integrity || !e.integrity.hash) { skipped++; continue; }
  const size = e.size;
  const off = contentStart + parseInt(e.offset, 10);
  if (off + size > fileSize) { bad++; badList.push(f.path + ' (вне файла)'); continue; }
  const buf = Buffer.alloc(size);
  fs.readSync(fd, buf, 0, size, off);
  const hash = crypto.createHash('sha256').update(buf).digest('hex');
  if (hash !== e.integrity.hash) { bad++; badList.push(f.path); }
  checked++;
}
fs.closeSync(fd);
console.log(JSON.stringify({ files: files.length, checked, skipped, bad }, null, 1));
if (bad) { console.log('НЕ СОВПАЛИ:'); for (const p of badList.slice(0, 20)) console.log(' -', p); process.exit(1); }
