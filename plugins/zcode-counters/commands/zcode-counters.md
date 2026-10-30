---
description: "Полоса счётчиков токенов над полем ввода ZCode (ходы/шаги/ток-с/сумма/кэш). Аргументы: пусто — статус; установить; откат."
---

# Счётчики токенов (zcode-counters)

Патчит интерфейс ZCode: над полем ввода появляется строка вида
`21 ход · 459 шагов · 29 ток/с · Σ 70.8 млн · кэш 49.9%`, обновляется раз в ~1 с.
Данные тянет из локального демона ctxdb (127.0.0.1:7717 /usage/latest); нет демона — полоса скрыта, ошибок нет.

## Аргументы

$ARGUMENTS

## Правила работы

- **(пусто) или `статус`** — только проверить: путь установки, версия, есть ли строка в текущем архиве, живой ли переключатель. Выполни:
  `powershell -NoProfile -Command "Select-String -Path 'C:\Program Files\ZCode\resources\app.asar' -Pattern 'data-zcode-counters=\"v1\"' -Quiet"`
  Найдено = установлено.
- **`установить`** — выполнить:
  `powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\er-ka\Documents\z-code\z-code-repo\z-code-main\plugins\zcode-counters\assets\apply.ps1"`
  Скрипт соберёт patched asar (запросит UAC через install.ps1), сохранит оригинал в
  `%LOCALAPPDATA%\ZCodeCounters\app.asar.backup` и поставит патч. После — сказать пользователю
  ZCode перезапустить полностью (трей → Выйти → снова запустить).
- **`откат`** — вернуть оригинальный архив:
  `powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\er-ka\Documents\z-code\z-code-repo\z-code-main\plugins\zcode-counters\assets\uninstall.ps1"`

## Важно

- Патч совместим с применённым русификатором: он правит только `out/renderer/index.html` внутри `app.asar`.
- Оригинал всегда лежит в `%LOCALAPPDATA%\ZCodeCounters\app.asar.backup`.
- После обновления ZCode строка исчезнет — повторить `установить`.
- Статус выдаётся байт-в-байт: не редактируй результаты, просто перескажи.
