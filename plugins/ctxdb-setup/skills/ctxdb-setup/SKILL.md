---
name: ctxdb-setup
description: Установить, настроить, проверить или перенести локальную векторную память ctxdb для ZCode (LanceDB + multilingual-e5-small). Использовать при первом развёртывании, ошибке dlopen/native-модулей, пропавших хуках, пустом поиске или переезде на другой компьютер.
---

# ctxdb-setup — векторная память ZCode

Полный плейбук установки с нуля, диагностики и переноса. Всё считается локально:
LanceDB (embedded) + `multilingual-e5-small` (384d, q8, ONNX, CPU). При работе в
сеть уходит только разовая загрузка весов модели (~129 МБ в `ctxdb\.cache`).

Каталог по умолчанию: `C:\Users\er-ka\Documents\z-code\ctxdb`.

## 0. Что должно быть

- Windows 10/11 x64.
- Node.js LTS в `PATH`.
- **Visual C++ Redistributable 2015-2022 x64** — обязательно. Без него native
  LanceDB не загружается: `dlopen`/`LoadLibrary` падает, `doctor` показывает
  `lancedb FAIL`.
- Каталог `ctxdb` с кодом: `package.json`, `src\cli.mjs`, `hooks\*.mjs`.
- Свободное место: ~130 МБ модель + база (зависит от истории).

## 1. Пререквизиты

```powershell
winget install --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
winget install --id Microsoft.VCRedist.2015+.x64 --accept-source-agreements --accept-package-agreements
node --version
```

После установки Node открой новое окно терминала — иначе `node` не найдётся в
`PATH`. VCRedist ставится один раз на машину и переживает переустановку ctxdb.

## 2. Каталог ctxdb

Исходники ctxdb не входят в этот репозиторий плагинов. Возьми каталог из своей
рабочей копии (`C:\Users\er-ka\Documents\z-code\ctxdb`) или из архива, который
переносишь вместе с папкой `Documents\z-code`. Проверь состав:

```powershell
Test-Path C:\Users\er-ka\Documents\z-code\ctxdb\package.json
Test-Path C:\Users\er-ka\Documents\z-code\ctxdb\src\cli.mjs
Test-Path C:\Users\er-ka\Documents\z-code\ctxdb\hooks\user-prompt.mjs
```

Три `True` — каталог на месте. Дальше все команды выполняются из него.

## 3. Зависимости

```powershell
cd C:\Users\er-ka\Documents\z-code\ctxdb
npm install
```

Важно: **install scripts должны быть разрешены**. `onnxruntime-node`, `sharp` и
`protobufjs` докачивают бинарники в postinstall. Если ставил с
`--ignore-scripts`, с `--omit=optional` или менеджер заблокировал скрипты —
`node_modules` останется без DLL и `.node`, и модель упадёт.

Проверка, что бинарники на месте (Windows x64):

```powershell
Test-Path node_modules\@lancedb\lancedb-win32-x64-msvc\lancedb.win32-x64-msvc.node
Test-Path node_modules\onnxruntime-node\bin\napi-v6\win32\x64\onnxruntime.dll
Test-Path node_modules\@img\sharp-win32-x64
```

Три `True` — можно дальше. Если `False`, повтори `npm install` без
`--ignore-scripts` и без `--omit=optional`; при упорной ошибке удали
`node_modules` (а `package-lock.json` не трогай) и выполни `npm ci`.

## 4. Диагностика

```powershell
node src\cli.mjs doctor
```

Здоровый вывод:

```
node               v26.13.0
каталог            C:\Users\er-ka\Documents\z-code\ctxdb
lancedb            ok
строк              408
демон              ok pid=224 ready=true
хуки в конфиге     ok
hooks.enabled      true
```

Версия Node и число строк зависят от машины; важны `lancedb ok`, живой демон и
установленные хуки.

Что означает не-`ok`:

| Строка | Причина и лечение |
|---|---|
| `lancedb FAIL ... dlopen` | нет VCRedist x64 — поставь из шага 1 и перезапусти терминал |
| `lancedb FAIL ... Cannot find module` | `npm install` не доставил `@lancedb/lancedb-win32-x64-msvc` |
| `демон не отвечает` | `node src\cli.mjs daemon start`; порт 7717 занят другим процессом — найди и заверши |
| `хуки в конфиге НЕ УСТАНОВЛЕНЫ` | `node src\cli.mjs install-hooks` |
| `конфиг` не читается | `%USERPROFILE%\.zcode\cli\config.json` повреждён; рядом лежит `.ctxdb-backup` |

## 5. Демон и индекс

```powershell
node src\cli.mjs daemon start
node src\cli.mjs ingest
node src\cli.mjs stats
```

- `daemon start` поднимает `ctxd` на `127.0.0.1:7717`, грузит модель (~2-3 с) и
  прогревает её.
- `ingest` индексирует историю инкрементально: первый прогон читает всё и может
  занять минуты, повторные — секунды. `ingest --full` перечитывает с нуля.
- `stats` показывает число фрагментов, модель, состояние демона.

Проверка поиска до подключения хуков:

```powershell
node src\cli.mjs search "как ставили русификатор" --context
```

## 6. Хуки

```powershell
node src\cli.mjs install-hooks
node src\cli.mjs doctor
```

`install-hooks` прописывает три события в `%USERPROFILE%\.zcode\cli\config.json`
(`SessionStart`, `UserPromptSubmit`, `Stop`) и делает бэкап
`config.json.ctxdb-backup`. В `doctor` должны появиться `хуки в конфиге ok` и
`hooks.enabled true`.

- `SessionStart` — поднимает демон и греет модель.
- `UserPromptSubmit` — ищет контекст и рутину, возвращает `additionalContext`.
- `Stop` — дописывает сессию в индекс (в этой сборке срабатывает нестабильно;
  корректность держится на watcher'е демона).

После установки хуков нужен **новый чат** (или перезапуск ZCode): конфиг хуков
читается при старте сессии.

Выключить автоподстановку: `node src\cli.mjs uninstall-hooks`.

## 7. Что попадает в промпт

- Поиск и эмбеддинги локальные — **0 токенов**.
- В промпт уходит `<recall>` с жёстким лимитом **900 символов ≈ 240 токенов**;
  при слабой релевантности блок не вставляется вообще.
- Рутина (если сработала) идёт отдельным блоком `<routine>` и тоже ограничена по
  смыслу: имя, статус, суть, путь к скиллу.
- Скорость: поиск в демоне 20-25 мс, полный путь хука 180-300 мс.

## 8. Разделение по проектам

Каждый фрагмент несёт `project` (ключ рабочего каталога), `project_path`,
`task_id`/`task_title`, `kind` (`chat_user`, `chat_assistant`, `memory`, `task`,
`todo`, `doc`, `instruction`, `routine`).

По умолчанию `scope: auto`: поиск идёт по всем проектам, свои фрагменты получают
бонус, в выводе группы помечены «текущий» / «другой проект». Жёстко ограничить:
`search "..." --project <key> --scope project`.

## 9. Перенос на другой компьютер

На старой машине:

```powershell
cd C:\Users\er-ka\Documents\z-code
.\zc.cmd backup --with-projects
```

Снимок ложится в `portable\`: `home\` (копия `~/.zcode`), `appdata\.zcode\`
(настройки, задачи, credentials), `ctxdb-data\` (векторная база), `secrets\gh\`,
`projects\` при `--with-projects`, `manifest.json`. Затем скопируй **всю** папку
`Documents\z-code` на новую машину.

На новой машине (ZCode **закрыт**):

```powershell
winget install --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
winget install --id Microsoft.VCRedist.2015+.x64 --accept-source-agreements --accept-package-agreements
cd <путь>\z-code
.\zc.cmd restore --dry-run
.\zc.cmd restore
```

`restore` возвращает оба дерева данных, перезаписывает абсолютные пути (хуки,
`installPath` плагинов, `dataBaseDir`), показывает список проектов и складывает
старые файлы в `portable\_before-restore\`. После — запусти ZCode, демон
поднимется сам на первой сессии.

Оговорки:

- Снимок по умолчанию **содержит секреты** (`credentials.json`, токен `gh`).
  Не включать: `backup --no-credentials`. Папку `portable\` храни как профиль
  пользователя, при передаче — шифруй.
- Пароли из Windows Credential Manager не экспортируются.
- Если `restore` запущен при открытом ZCode, база чатов занята — закрой
  приложение полностью (трей → «Выйти»).

## 10. Диагностика в эксплуатации

- Лог демона: `data\ctxd.log`. Отладка хуков: `data\hook-debug.log` (включается
  `CTXDB_DEBUG=1`).
- Актуальность: демон слушает WAL `db.sqlite`, `tasks-index.sqlite` и каталог
  памяти — доиндексация через ~0.4 с после записи, плюс страховочный опрос раз в
  60 с.
- Пустой поиск: проверь `stats` (строки), затем `ingest`; при смене
  `dataBaseDir` в `setting.json` старый `v2` может оказаться устаревшей копией.
- Демон не отвечает: `daemon stop`, проверь порт 7717, `daemon start`.
- Сброс базы: удалить `data\lancedb` и `data\state.json`, затем `ingest --full`.
- Правки кода демона: `daemon stop` и `daemon start`.

## 11. Ограничения

- Windows-only: пути, хуки и демон рассчитаны на Windows.
- Индексируются текстовые части сообщений; вывод инструментов и `reasoning` в
  индекс не попадают — это шум.
- Короткие реплики (меньше 12 символов, «да», «ок») хук пропускает.
- Качество на очень коротких промптах низкое — лучше формулировать задачу.
- Синтетические и служебные части сессии не индексируются.
- Модель скачивается один раз; без сети первый запуск не прогреется.
- `Stop`-хук нестабилен: не полагайся на него как на единственный триггер
  индексации.
