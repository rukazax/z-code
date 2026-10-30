# Changelog

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
