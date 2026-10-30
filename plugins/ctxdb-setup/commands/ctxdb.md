---
description: Установить, проверить или перенести локальную векторную память ctxdb — демон, хуки, поиск, снимок
---

Пользователь вызвал `/ctxdb`. Действуй по скиллу `ctxdb-setup` из плагина
`ctxdb-setup`. Все команды идут через CLI ctxdb:

```
node "C:\Users\er-ka\Documents\z-code\ctxdb\src\cli.mjs" <команда>
```

1. Определи режим по тексту после команды:
   - пусто или `статус`/`status` — `doctor` и `stats`: проверь Node, LanceDB,
     число строк, демон, хуки в конфиге; перескажи результат человеческим
     языком, отметь FAIL и «не отвечает»;
   - `установить`/`install` — пройди playbook из скилла `ctxdb-setup`:
     пререквизиты (Node LTS, VCRedist), `npm install` с разрешёнными install
     scripts, `doctor`, `ingest`, `daemon start`, `install-hooks`;
   - `демон start|stop|restart`/`daemon ...` — `daemon start`, `daemon stop`;
     для `restart` сначала `stop`, потом `start`;
   - `хуки вкл|выкл`/`hooks on|off` — `install-hooks` или `uninstall-hooks`,
     затем `doctor` для проверки;
   - `переезд`/`migrate` — инструкции снимка и восстановления:
     `backup --with-projects`, копирование папки, `restore --dry-run`,
     `restore`; напомни, что на новой машине ZCode должен быть закрыт;
   - `поиск <запрос>`/`search <запрос>` — `search "<запрос>" --context`, покажи
     готовый блок и 2-3 верхних фрагмента с проектом и датой;
   - `проекты`/`projects` — `projects`: разбивка по проектам, задачам и видам.
2. Не выдумывай пути и числа: бери их из вывода команд. Если демон не отвечает,
   сначала `daemon start`, потом повторяй проверку.
3. Показывай предупреждение о секретах, если речь о `backup`: снимок по
   умолчанию включает `credentials.json`; исключить — `--no-credentials`.
4. Ничего не удаляй без явной просьбы: сброс базы — только через
   `ingest --full`, удаление `data\lancedb` и `data\state.json` — назвать
   последствия и спросить.
5. `routines status` упоминай как отдельную диагностику майнера рутин, а не как
   часть установки.

Аргумент пользователя: $ARGUMENTS
