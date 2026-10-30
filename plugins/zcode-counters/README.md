# zcode-counters · Счётчики токенов над полем ввода

Полоса как в DeepSeek Harness: **ходы · шаги · ток/с · Σ токенов · попадание в кэш** —
обновляется раз в секунду, над самым местом работы. 📊

ZCode сами токены не показывает рядом с вводом, а они уже посчитаны в базе чатов
(`turn_usage`, `tool_usage`). Плагин патчит только `out/renderer/index.html`
внутри `app.asar` — вставляет DOM-оверлей, который тянет цифры с локального
демона ctxdb (`127.0.0.1:7717`).

- демона нет → полоса тихо скрыта, ошибок нет;
- работает вместе с русификатором (патчи не пересекаются);
- оригинал всегда в `%LOCALAPPDATA%\ZCodeCounters\app.asar.backup`;
- после обновления ZCode — повторить установку.

## Установка / откат

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File assets\apply.ps1     # установить (UAC)
powershell -NoProfile -ExecutionPolicy Bypass -File assets\uninstall.ps1 # откатить
```

Или из чата:

```
/zcode-counters            - статус
/zcode-counters установить - поставить полосу
/zcode-counters откат      - вернуть оригинальный интерфейс
```

Полное описание и схема — [docs/ru/zcode-counters.md](../../docs/ru/zcode-counters.md)
· English: [docs/en/zcode-counters.md](../../docs/en/zcode-counters.md)
