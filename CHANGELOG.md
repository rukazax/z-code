# Changelog

## 2026-10-31 — routine-miner 1.1.1: триггерный мешок и содержательные слова

RU: в скоринг добавлены две правки по итогам калибровки. Мешок рутины теперь собирается
**только из триггеров** (фраза + частотные слова кластера) — раньше туда попадали все слова
длинных образцов, и запросы вроде «покажи список файлов в текущей папке» цеплялись за
github-рутину через «файлов/папке». Плюс бонус +0.03, когда есть якорь и минимум два
содержательных слова (длина ≥ 5). Калибровка: реальные повторы 0.456–0.528, ложные ≤ 0.431,
порог 0.45 разделяет чисто.

EN: two scoring fixes after calibration. A routine's bag is now built **from triggers only**
(phrase + frequent cluster words) — previously it absorbed every word of long samples, so
prompts like “Покажи список файлов в текущей папке” matched the github routine via
“файлов/папке”. Added a +0.03 bonus when there is an anchor and at least two content words
(length ≥ 5). Calibration: real repeats 0.456–0.528, false matches ≤ 0.431; the 0.45 threshold
separates cleanly.

## 2026-10-31 — routine-miner 1.1.0: точность срабатывания

RU: порог поднят с 0.38 до **0.45**, а скоринг переделан: у каждого слова появился вес
по редкости (IDF по рутинам), и совпадение засчитывается уверенно только при наличии
**якоря** — слова, уникального для конкретной рутины. Без якоря счёт гасится втрое.
Калибровка на живых промптах (`tools/calibrate-routines.mjs`): реальные повторы дают
0.46–0.80, случайные совпадения — 0.01–0.41. Проверка через `/hook/prompt`:
«снова подключи github…» → блок есть; «Добавь после цифр…» и «Подними порог…» → блока нет.

EN: threshold raised from 0.38 to **0.45**, and scoring reworked: every word is weighted by
rarity (IDF across routines), and a match only counts confidently when there is an **anchor** —
a word unique to that routine. Without an anchor the score is damped threefold. Calibrated on
live prompts (`tools/calibrate-routines.mjs`): real repeats score 0.46–0.80, accidental matches
0.01–0.41. Verified through `/hook/prompt`: “снова подключи github…” injects the block;
“Добавь после цифр…” and “Подними порог…” do not.

## 2026-10-31 — zcode-counters 1.4.0: смешанная семантика счётчиков

RU: **ток/с и кэш % теперь считаются по всем сессиям** (это свойство канала и префикса,
а не одного чата), а **ходы, шаги и сумма остаются по текущей сессии/задаче**.
Формулы: скорость — последний по времени ход любой сессии, кэш — `sum(cache_read) /
(sum(cache_read) + sum(input))` по всей базе. Оверлей не менялся, только данные демона.

EN: **tokens/s and cache % are now computed across all sessions** (a channel/prefix
property, not a chat one), while **turns, steps and the total stay per current
session/task**. Formulas: speed from the freshest turn of any session, cache as
`sum(cache_read) / (sum(cache_read) + sum(input))` over the whole database. The overlay
itself did not change — only the daemon data.

## 2026-10-31 — zcode-counters 1.3.0: подписи после цифр

RU: после каждого числа появилась подпись, как в DeepSeek Harness: **ходов · шагов ·
ток/с · ток · кэш**. Строка читается без легенды: `⏱ 26 ходов · ⧉ 558 шагов · ⚡ 87 ток/с ·
▤ 105.9 млн ток · ◔ 49.8% кэш`. Логика счёта прежняя — текущая сессия/задача, живой опрос.

EN: every number now carries a label as in DeepSeek Harness: **ходов · шагов · ток/с · ток ·
кэш**. The line reads without a legend: `⏱ 26 ходов · ⧉ 558 шагов · ⚡ 87 ток/с · ▤ 105.9M ток ·
◔ 49.8% кэш`. Counting stays the same — current session/task, live polling.

## 2026-10-31 — zcode-counters 1.2.0: показатели по текущей сессии

RU: ходы, шаги и сумма считаются **только по текущей сессии/задаче** — той, у которой
самая свежая активность (`session.time_updated`); пока ты пишешь в чате, ZCode обновляет
именно её. Остальное без изменений: вставка справа от «Working», шрифт копируется,
анимированные иконки, живой опрос 350 мс при активном ходе. Для отладки добавлен
`/usage/latest?session=<id>`.

EN: turns, steps and the total now cover **the current session/task only** — the one with
the freshest activity (`session.time_updated`); while you type in a chat, ZCode keeps that
session updated. Everything else stays: inline insertion next to “Working”, copied font,
animated icons, 350 ms live polling during a turn. Added `/usage/latest?session=<id>`
for debugging.

## 2026-10-31 — zcode-counters 1.1.0: счётчики в строке Working, суммарные по всем сессиям

RU: строка больше не висит отдельной плашкой — оверлей находит элемент «Working»/«Работает»
и вставляется **справа от него**, копируя вычисленный шрифт, кегль и цвет (выглядит нативно).
Показатели сокращены до иконок с анимацией: `⏱ ходы · ⧉ шаги · ⚡ ток/с · ▤ Σ · ◔ кэш %` —
пульс `opacity` у всех и вращение у «кэша»; пока идёт ход, анимация ускоряется.

Цифры **суммарные по всем сессиям и проектам** (общий счётчик установки), считаются в
реальном времени: пока ход не завершён, он тоже учитывается, а опрос идёт раз в 350 мс
(в покое — 1 с). Папка/название сессии из строки убраны.

Вставку держит `MutationObserver` — React перерисовывает индикатор часто. Патч стал
идемпотентным: предыдущий блок вырезается и заменяется, поэтому установка поверх старой
версии не требует отката. Код оверлея вынесен в `assets/overlay.js`.

EN: the strip is no longer a floating pill — the overlay finds the "Working" indicator and
inserts itself **right after it**, copying the computed font, size and colour so it looks native.
Metrics are icon-led and animated: `⏱ turns · ⧉ steps · ⚡ tok/s · ▤ Σ · ◔ cache %`, with an
opacity pulse plus one rotating icon; the animation speeds up while a turn is running.

Numbers are **summed across all sessions and projects** (an installation-wide counter) and
updated live: the unfinished turn is included, polling runs at 350 ms while active and 1 s when
idle. The session folder/name is no longer shown.

A `MutationObserver` keeps the insertion alive through React re-renders. Patching is idempotent:
the previous block is stripped and replaced, so re-installing over an older version works without
a rollback. The overlay code moved to `assets/overlay.js`.

## 2026-10-31 — zcode-counters: счётчики токенов над полем ввода

RU: новый пакет `zcode-counters` — полоса счётчиков как в DeepSeek Harness, над полем ввода ZCode:
**ходы · шаги · ток/с · Σ токенов · попадание в кэш**. Патчит только `out/renderer/index.html`
внутри `app.asar` — вставляет DOM-оверлей (~1.6 КБ), который раз в ~0.9 с читает
`GET /usage/latest` локального демона ctxdb и обновляет один текстовый узел. Демона нет —
полоса тихо скрыта. Данные: «Ходы» — `turn_usage`, «Шаги» — `tool_usage`, «Ток/с» —
`output_tokens / (completed_at − first_token_at)` последнего хода, «Σ» — сумма `computed_total_tokens`,
«Кэш» — `cache_read / (cache_read + input)` по сессии.

Совместим с русификатором (правки не пересекаются), SHA-256 изменённого файла пересчитывается,
оригинал сохраняется в `%LOCALAPPDATA%\ZCodeCounters\app.asar.backup`, есть `uninstall.ps1`.
Проверено на живой сессии: 21 ход, 459 шагов, кэш 49.9%. Обновление ZCode сбрасывает строку —
установку повторить; при изменении структуры бандла патчер выходит с понятной ошибкой, ничего не записав.

Оформление: манифест, команда `/zcode-counters` (статус, установить, откат), скилл `zcode-counters`,
двуязычные `docs/ru/zcode-counters.md` и `docs/en/zcode-counters.md`, схема `assets/zcode-counters-{ru,en}.svg`.

EN: new `zcode-counters` package — a DeepSeek-Harness-style token strip above the ZCode input
field: **turns · steps · tok/s · Σ tokens · cache hit**. It patches only `out/renderer/index.html`
inside `app.asar`, injecting a ~1.6 KB DOM overlay that polls `GET /usage/latest` on the local
ctxdb daemon every ~0.9 s and updates one text node. No daemon → the strip stays hidden. Data:
turns from `turn_usage`, steps from `tool_usage`, tok/s from the last turn's
`output_tokens / (completed_at − first_token_at)`, Σ from `computed_total_tokens`, cache from
`cache_read / (cache_read + input)`.

Co-exists with the russifier, SHA-256 recalculated for the changed file, the original is kept in
`%LOCALAPPDATA%\ZCodeCounters\app.asar.backup`, `uninstall.ps1` restores it. Verified on a live
session: 21 turns, 459 steps, cache 49.9%. A ZCode update removes the strip — apply again; if the
bundle layout changes, the patcher exits with a clear message and writes nothing.

## 2026-10-31 — routine-miner: скилы из повторяющихся задач

RU: новый пакет `routine-miner` — майнер типовых действий. Он читает запросы пользователя из индекса
ctxdb (`kind=chat_user`), дедуплицирует их и кластеризует по эмбеддингам `multilingual-e5-small`:
косинус ≥ 0.87, минимум два запроса в кластере. Кластер превращается в `routines\<id>\SKILL.md` —
суть, до трёх шагов «как это обычно делалось» из прошлых ответов агента, триггеры и правила
применения — и запись в `routines\routines.json` с `uses`, `status` и путём к скиллу. Каждая рутина
дополнительно индексируется чанком `kind=routine`, поэтому находится и обычным поиском.

Подстановка: на `UserPromptSubmit` хук ищет лучшую рутину по нечёткому покрытию слов (точное
совпадение, префикс для слов от 5 символов, общий корень из 4 символов) и порогу 0.38. Ниже порога
блок `<routine>` не вставляется — 0 токенов. Сама навигация в блоке (имя, статус, `uses`, суть) стоит
~40-60 токенов, вместе с абсолютным путём к скиллу — ~130; полный `SKILL.md` (~250-350 токенов)
читается только по требованию.

Проверено на живой базе: 3 рутины, 8 суммарных повторов. Реальный кейс — четыре запроса про
подключение GitHub-аккаунта, собранные в рутину `github-plugin-github-zcode-plugins-offic`;
`routines test "подключим аккаунт github в zcode"` даёт score 0.51, хук подставляет блок вместо
повторного разбора. Ограничения записаны честно: мало истории — мало рутин, стемминг наивный,
сложные процедуры майнер не заменяет.

Оформление: манифест, команда `/routine-miner` (статус, скан, проверить, забыть, открыть), скилл
`routine-miner`, двуязычный README, страницы `docs/ru/routine-miner.md` и `docs/en/routine-miner.md`,
схемы `assets/routine-miner-{ru,en}.svg`, запись в `marketplace.json`.

EN: new `routine-miner` package — a miner for repeated actions. It reads user prompts from the ctxdb
index (`kind=chat_user`), de-duplicates and clusters them with `multilingual-e5-small` embeddings:
cosine ≥ 0.87, at least two prompts per cluster. A cluster becomes `routines\<id>\SKILL.md` — summary,
up to three "how it was usually done" steps from past agent answers, triggers and application rules —
plus a `routines\routines.json` entry with `uses`, `status` and the skill path. Every routine is also
indexed as a `kind=routine` chunk, so regular search finds it too.

Injection: on `UserPromptSubmit` the hook matches the best routine by fuzzy word coverage (exact match,
prefix for words of 5+ characters, shared four-character root) at a 0.38 threshold. Below it no
`<routine>` block is injected — 0 tokens. The navigation part of the block (name, status, `uses`,
summary) costs ~40-60 tokens, ~130 with the absolute skill path; the full `SKILL.md` (~250-350 tokens)
is read only on demand.

Verified on a live database: 3 routines, 8 total repeats. A real case is four prompts about connecting
a GitHub account packed into the `github-plugin-github-zcode-plugins-offic` routine;
`routines test "подключим аккаунт github в zcode"` returns score 0.51 and the hook injects the block
instead of re-deriving. Limitations are stated plainly: little history means few routines, stemming is
naive, and complex procedures are not replaced.

Delivery: manifest, `/routine-miner` command (status, scan, test, forget, open), the `routine-miner`
skill, a bilingual README, `docs/ru/routine-miner.md` and `docs/en/routine-miner.md`,
`assets/routine-miner-{ru,en}.svg` diagrams and a `marketplace.json` entry.

## 2026-10-31 — ctxdb-setup: векторная память ZCode

RU: новый пакет `ctxdb-setup` — установка, диагностика и перенос локальной векторной памяти ctxdb
(LanceDB + `multilingual-e5-small`, 384d q8 ONNX CPU). Главная часть — полный плейбук установки:
пререквизиты (Node.js LTS и **обязательный** Visual C++ Redistributable 2015-2022 x64 — без него
native LanceDB падает на `dlopen`), получение каталога ctxdb, `npm install` с разрешёнными install
scripts для `onnxruntime-node` и `sharp` (иначе в `node_modules` нет DLL и `.node`), `doctor`,
`ingest`, `daemon start`, `install-hooks`. Для каждого шага — проверка и разбор типовых FAIL.

Цифры: поиск в демоне 20-25 мс, полный путь хука 180-300 мс, 0 токенов на поиск, вставка
`<recall>` ≤ 900 символов ≈ 240 токенов, модель ~129 МБ в кэше. Перенос: `zc backup --with-projects`
на старой машине, копирование всей папки `Documents\z-code`, `zc restore --dry-run` и `zc restore`
на новой при **закрытом** ZCode; возвращаются оба дерева (`home`, `appdata\.zcode`), пути хуков и
плагинов перезаписываются. Снимок по умолчанию содержит секреты — исключить: `--no-credentials`.

Оформление: манифест, команда `/ctxdb` (статус, установить, демон, хуки, переезд, поиск, проекты),
скилл `ctxdb-setup`, двуязычный README, страницы `docs/ru/ctxdb-setup.md` и
`docs/en/ctxdb-setup.md`, схемы `assets/ctxdb-{ru,en}.svg`, запись в `marketplace.json`.

EN: new `ctxdb-setup` package — installation, diagnostics and migration for the local ctxdb vector
memory (LanceDB + `multilingual-e5-small`, 384d q8 ONNX CPU). The core is a complete install playbook:
prerequisites (Node.js LTS and a **mandatory** Visual C++ Redistributable 2015-2022 x64 — without it
native LanceDB fails on `dlopen`), obtaining the ctxdb directory, `npm install` with install scripts
allowed for `onnxruntime-node` and `sharp` (otherwise `node_modules` has no DLL or `.node`), `doctor`,
`ingest`, `daemon start`, `install-hooks`. Every step has a verification and a mapping of typical
FAILs to causes.

Numbers: 20-25 ms search inside the daemon, 180-300 ms full hook path, 0 tokens per search, a
`<recall>` injection of ≤ 900 chars ≈ 240 tokens, a ~129 MB model cache. Migration:
`zc backup --with-projects` on the old machine, copy the whole `Documents\z-code` folder, then
`zc restore --dry-run` and `zc restore` on the new one with ZCode **closed**; both trees (`home`,
`appdata\.zcode`) are restored and hook/plugin paths are rewritten. The snapshot contains secrets by
default — exclude them with `--no-credentials`.

Delivery: manifest, `/ctxdb` command (status, install, daemon, hooks, migration, search, projects), the
`ctxdb-setup` skill, a bilingual README, `docs/ru/ctxdb-setup.md` and `docs/en/ctxdb-setup.md`,
`assets/ctxdb-{ru,en}.svg` diagrams and a `marketplace.json` entry.

## 2026-10-30 — zcode-ru: русский интерфейс ZCode

RU: новый пакет `zcode-ru` — русский интерфейс ZCode Desktop 3.16.3. Перевод собран из десяти
публичных русификаторов ZCode и сверен с эталонным каталогом `en-US`, извлечённым из установленного
приложения: 6999 ключей, из них 6818 со связным русским текстом, остальное — названия продуктов
(`Discord`, `Telegram`) и строки-форматы (`{count} файлов`). Помимо каталога переводятся нативное
меню (23 из 50 пунктов, остальные — бренды), диалоги обновления и «О программе» (32 из 32), шаблоны
автоматизаций и известные серверные попапы.

Ключевое решение — не поставлять готовый архив: 350 МБ `app.asar` привязывают перевод к одной версии
и ломаются после обновления. Вместо этого `patch.js` собирает архив из той установки, которая есть на
машине: находит каталог в бандле, сопоставляет ключи с `ru-RU.json`, пересчитывает SHA-256 изменённых
файлов в заголовке и пишет результат рядом. Установка — `install.ps1`: сохранение оригинала в
`%LOCALAPPDATA%\ZCodeRu\app.asar.backup`, запрос UAC, запись поверх занятого файла, если ZCode
запущен. Откат — `uninstall.ps1`, диагностика без прав администратора — `check.ps1`.

По ходу работы исправлены три дефекта, которые есть в готовых русификаторах: 15 строк записаны в
бандле кавычками другого типа и оставались английскими; 11 строк содержат обратные кавычки и обратные
слэши и ломают разбор без экранирования под шаблонные литералы; пять ключей (`chat.captcha.verifyFailed`
и соседние) лежат в общем объекте-оверрайде вне каталога и не попадали под замену. Проверено: сборка
из стокового бэкапа побайтно совпала с установленным архивом (SHA-256 `b2183d64…`), изменённые чанки
проходят `node --check`, `check.ps1` подтверждает русский интерфейс на живой установке.

Оформление: двуязычный README, страницы `docs/ru/zcode-ru.md` и `docs/en/zcode-ru.md`, баннер
`assets/banner.svg`, схемы `assets/architecture-{ru,en}.svg`, скилл `zcode-ru`, команда
`/rusifikator`, SessionStart-хук с напоминанием после обновления, `marketplace.json` для установки
репозитория как маркетплейса.

EN: new `zcode-ru` package — a Russian UI for ZCode Desktop 3.16.3. The translation was assembled from
ten public ZCode localizations and checked against the `en-US` reference catalog extracted from the
installed app: 6999 keys, 6818 of them with coherent Russian text, the rest being product names
(`Discord`, `Telegram`) and format strings (`{count} files`). Beyond the catalog it translates the
native menu (23 of 50 items, the rest are brands), the update and about dialogs (32 of 32), automation
templates and known server-side popups.

The key decision is not to ship a ready-made archive: a 350 MB `app.asar` pins the translation to one
version and breaks after an update. Instead `patch.js` builds the archive from whatever installation is
present: it locates the catalog inside the bundle, matches keys against `ru-RU.json`, recalculates the
SHA-256 of changed files in the header and writes the result next to the source. Installation is
`install.ps1`: the original is kept in `%LOCALAPPDATA%\ZCodeRu\app.asar.backup`, UAC is requested, and
the file is written in place when ZCode is running. Rollback is `uninstall.ps1`, read-only diagnostics
without elevation is `check.ps1`.

Three defects present in existing localizations were fixed along the way: 15 strings are stored with a
different quote style in the bundle and stayed English; 11 strings contain backticks and backslashes and
break parsing without template-literal escaping; five keys (`chat.captcha.verifyFailed` and neighbours)
live in a shared override object outside the catalog and were never replaced. Verified: a build from the
stock backup matched the installed archive byte for byte (SHA-256 `b2183d64…`), the changed chunks pass
`node --check`, and `check.ps1` confirms a Russian UI on a live installation.

Delivery: bilingual README, `docs/ru/zcode-ru.md` and `docs/en/zcode-ru.md` pages, `assets/banner.svg`,
diagrams `assets/architecture-{ru,en}.svg`, the `zcode-ru` skill, the `/rusifikator` command, a
SessionStart hook that warns after an update, and `marketplace.json` so the repository works as a
marketplace.
