# ctxdb-setup — векторная память ZCode

Плагин ставит и настраивает локальную векторную память для ZCode: LanceDB +
`multilingual-e5-small` (384d, q8, ONNX CPU). Все чаты, задачи, память агента и
документы индексируются один раз и подмешиваются в новый промпт автоматически —
с разделением по проектам. Поиск локальный: **0 токенов**.

## Что даёт

- Контекст из прошлых чатов в каждом новом — без ручного копирования.
- Разделение по `project` / `task_id`: видно, откуда фрагмент и что он из другого
  проекта.
- Перенос установки одной папкой: `backup` → копирование → `restore`.
- Автоподстановка через хуки ZCode; выключается одной командой.

## Что внутри

| Файл | Назначение |
|---|---|
| `.zcode-plugin/plugin.json` | манифест, компоненты `skills` и `commands` |
| `commands/ctxdb.md` | слэш-команда `/ctxdb` |
| `skills/ctxdb-setup/SKILL.md` | полный плейбук: пререквизиты, установка, диагностика, переезд |

Код ctxdb живёт отдельно, в `C:\Users\er-ka\Documents\z-code\ctxdb`; плагин
описывает, как его поставить и чем проверять.

## Установка вкратце

```powershell
winget install --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements
winget install --id Microsoft.VCRedist.2015+.x64 --accept-source-agreements --accept-package-agreements

cd C:\Users\er-ka\Documents\z-code\ctxdb
npm install
node src\cli.mjs doctor
node src\cli.mjs ingest
node src\cli.mjs daemon start
node src\cli.mjs install-hooks
```

VCRedist обязателен: без него native LanceDB падает на `dlopen`. `npm install`
должен выполнить install scripts — иначе в `node_modules` не будет DLL
`onnxruntime` и `.node` LanceDB.

## Использование

```
/ctxdb                    — doctor + stats
/ctxdb установить         — полный playbook установки
/ctxdb демон start|stop|restart
/ctxdb хуки вкл|выкл
/ctxdb переезд            — backup/restore
/ctxdb поиск <запрос>
/ctxdb проекты
```

## Числа

| Метрика | Значение |
|---|---|
| Поиск в демоне | 20-25 мс |
| Полный путь хука | 180-300 мс |
| Токенов на поиск | 0 |
| Вставка в промпт | ≤ 900 символов ≈ 240 токенов |
| Модель в кэше | ~129 МБ |
| Ранжирование | 0.68·cos + 0.32·лексика |

## Требования и ограничения

- Windows-only; Node.js LTS; VCRedist x64.
- ZCode должен быть закрыт на время `restore` — база чатов занята приложением.
- Снимок `backup` по умолчанию содержит секреты; исключить — `--no-credentials`.
- Вывод инструментов и `reasoning` не индексируются; короткие реплики хук
  пропускает.
- `Stop`-хук нестабилен: актуальность держится на watcher'е и периодической
  доиндексации.

Полная страница: [`docs/ru/ctxdb-setup.md`](../../docs/ru/ctxdb-setup.md) ·
[English](../../docs/en/ctxdb-setup.md). Лицензия MIT.
