# Правила разработки и публикации · Contributing rules

**RU** · [English](#english)

## RU

### 1. Общий контур

1. Каждый плагин ZCode оформляется как самостоятельный пакет в `plugins/<name>`.
2. Обязательные файлы пакета: `.zcode-plugin/plugin.json`, `README.md`, `LICENSE` при отдельной
   лицензии.
3. Для пакета со скриптами обязательна проверка перед публикацией: `node --check` для JavaScript,
   разбор парсером для PowerShell.
4. Репозиторий публикует также `marketplace.json` — по нему он добавляется в ZCode как маркетплейс.

### 2. Глобальное правило публикации

> **Все разрабатываемые по ходу работы плагины и расширения ZCode выкладываются в GitHub-репозиторий
> [`rukazax/z-code`](https://github.com/rukazax/z-code) и оформляются по правилам ниже — без
> отдельного запроса и подтверждения пользователя.**

Правило действует по умолчанию для новых плагинов, расширений, скиллов, команд, хуков и их обновлений
в рамках работы с ZCode. Исключения: пакет содержит секреты или персональные данные; пользователь явно
отменил публикацию; публикация технически невозможна (фиксируется причина).

### 3. Оформление публикации

1. Описание — двуязычное: русский и английский, в одном `README.md` с переходом по якорю `#english`.
2. Обязательные разделы: назначение, состав, архитектура со схемой, быстрый старт, правила,
   безопасность, ограничения, лицензия.
3. Изображения и схемы — в `assets/`; в README дополнительно Mermaid-диаграмма.
4. Страницы пакетов — `docs/ru/<name>.md` и `docs/en/<name>.md` со ссылками друг на друга.
5. Текст — деловой, точный, без маркетинговых оборотов; терминология единая в RU и EN.
6. Ограничения описываются честно: что не работает и при каких условиях.

### 4. Проверка перед публикацией

- [ ] `.zcode-plugin/plugin.json` валиден, имя совпадает с именем каталога пакета.
- [ ] Все объявленные компоненты (`skills`, `commands`, `hooks`) существуют по указанным путям.
- [ ] `README.md` двуязычный, команды проверены на живой установке.
- [ ] Скрипты проходят проверку синтаксиса; smoke-тест выполнен.
- [ ] В репозитории нет токенов, паролей, cookie и персональных данных.
- [ ] `CHANGELOG.md` дополнен записью `RU:` / `EN:`.

### 5. Коммиты и версии

- Сообщения коммитов: `<type>: <краткое описание>` (`feat`, `fix`, `docs`, `chore`).
- Версии — по SemVer; изменения фиксируются в `CHANGELOG.md`.
- Ветка по умолчанию — `main`; публикация идёт прямо в неё.

---

## English

### 1. Scope

1. Every ZCode plugin is a standalone package under `plugins/<name>`.
2. Required package files: `.zcode-plugin/plugin.json`, `README.md`, and `LICENSE` when the package has
   its own license.
3. A package with scripts must be verified before publishing: `node --check` for JavaScript, a parser
   pass for PowerShell.
4. The repository also ships `marketplace.json`, so it can be added to ZCode as a marketplace.

### 2. Global publishing rule

> **Every ZCode plugin and extension developed during the work is published to the
> [`rukazax/z-code`](https://github.com/rukazax/z-code) GitHub repository and formatted by the rules
> below — without a separate user request or confirmation.**

The rule applies by default to new plugins, extensions, skills, commands, hooks and their updates within
ZCode work. Exceptions: the package contains secrets or personal data; the user explicitly cancels
publication; publishing is technically impossible (the reason is recorded).

### 3. Publication format

1. Bilingual description: Russian and English in one `README.md`, with an `#english` anchor for the
   switch.
2. Required sections: purpose, contents, architecture with a diagram, quick start, rules, security,
   limitations, license.
3. Images and diagrams in `assets/`; a Mermaid diagram in the README as well.
4. Package pages: `docs/ru/<name>.md` and `docs/en/<name>.md` linking to each other.
5. Text is concise and precise, with no marketing phrasing; terminology is consistent across RU and EN.
6. Limitations are stated plainly: what does not work and under which conditions.

### 4. Pre-publish checklist

- [ ] `.zcode-plugin/plugin.json` is valid and its name matches the package directory.
- [ ] Every declared component (`skills`, `commands`, `hooks`) exists at the declared path.
- [ ] `README.md` is bilingual and its commands were checked on a live installation.
- [ ] Scripts pass a syntax check and the smoke test was run.
- [ ] No tokens, passwords, cookies or personal data in the repository.
- [ ] `CHANGELOG.md` has a `RU:` / `EN:` entry.

### 5. Commits and versions

- Commit messages: `<type>: <short description>` (`feat`, `fix`, `docs`, `chore`).
- Versions follow SemVer; changes are recorded in `CHANGELOG.md`.
- The default branch is `main`; publishing goes straight into it.
