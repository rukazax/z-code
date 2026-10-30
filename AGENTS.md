# AGENTS.md — правила работы с репозиторием · Working rules

**RU** · [English](#english)

## RU

### 1. Обязательная публикация

> **Все разрабатываемые по ходу работы плагины и расширения ZCode выкладываются в этот
> репозиторий ([`rukazax/z-code`](https://github.com/rukazax/z-code)) и оформляются по правилам ниже —
> без отдельного запроса и подтверждения пользователя.**

Правило действует по умолчанию для новых плагинов, расширений, скиллов, команд и хуков, а также их
обновлений. Исключения: секреты или персональные данные в пакете; явная отмена пользователем;
техническая невозможность (фиксируется причина).

### 2. Оформление

1. Пакет — в `plugins/<name>`, имя манифеста совпадает с именем каталога.
2. `README.md` двуязычный, с переходом по якорю `#english`; страницы в `docs/ru` и `docs/en`.
3. Схемы — Mermaid в README и `docs`, изображения — в `assets/`, обе версии схемы (RU и EN).
4. Текст — деловой, точный, структурный; ограничения описываются честно.
5. Секреты, токены, cookie и персональные данные в репозиторий не попадают.

### 3. Порядок

1. Разработать и проверить пакет: `node --check`, разбор PowerShell, smoke-тест.
2. Обновить `CHANGELOG.md` записью `RU:` / `EN:`.
3. Поднять версию в `.zcode-plugin/plugin.json` и в `marketplace.json`.
4. Опубликовать в ветку `main`.
5. При невозможности — зафиксировать блокировку и причину.

---

## English

### 1. Mandatory publishing

> **Every ZCode plugin and extension developed during the work is published to this repository
> ([`rukazax/z-code`](https://github.com/rukazax/z-code)) and formatted by the rules below — without a
> separate user request or confirmation.**

The rule applies by default to new plugins, extensions, skills, commands and hooks, and to their
updates. Exceptions: secrets or personal data in the package; the user cancels explicitly; publishing is
technically impossible (the reason is recorded).

### 2. Format

1. A package lives in `plugins/<name>`; the manifest name matches the directory name.
2. `README.md` is bilingual with an `#english` anchor; pages live in `docs/ru` and `docs/en`.
3. Diagrams are Mermaid in the README and `docs`; images live in `assets/`, with both RU and EN versions.
4. Text is concise, precise and structured; limitations are stated plainly.
5. Secrets, tokens, cookies and personal data never enter the repository.

### 3. Order

1. Build and verify the package: `node --check`, PowerShell parser pass, smoke test.
2. Add a `RU:` / `EN:` entry to `CHANGELOG.md`.
3. Bump the version in `.zcode-plugin/plugin.json` and in `marketplace.json`.
4. Publish to the `main` branch.
5. If publishing is impossible, record the blocker and its cause.
