# zcode-ru — русская локализация ZCode

Плагин ставит полный русский перевод интерфейса ZCode Desktop (Windows):
каталог строк, меню приложения, диалоги обновления, шаблоны автоматизаций.

Перевод собран из всех публичных русификаторов ZCode на GitHub и сверен с
эталонным `en-US` установленной версии (3.16.3 на момент сборки): 6999 ключей
каталога, из них 6818 со связным русским текстом, остальное — названия
продуктов (`Discord`, `Telegram`) и строки-форматы (`{count} файлов`).

## Что внутри

| Файл | Назначение |
|---|---|
| `assets/translations/ru-RU.json` | каталог `ключ → русский текст`, 6999 строк |
| `assets/patch.js` | сборщик патченного `app.asar` из текущей установки ZCode |
| `assets/apply.ps1` | сборка + установка (установка запросит UAC) |
| `assets/install.ps1` | только установка готового архива, с бэкапом |
| `assets/uninstall.ps1` | откат к оригиналу из бэкапа |
| `assets/check.ps1` | статус: путь, версия, русский ли интерфейс, есть ли бэкап |
| `assets/hook-check.ps1` | тихая проверка на старте сессии: напомнит, если обновление сбросило перевод |
| `skills/zcode-ru/SKILL.md` | инструкции для агента |
| `commands/rusifikator.md` | слэш-команда `/rusifikator` |

## Использование

Из чата:

```
/rusifikator          — установить или обновить
/rusifikator статус   — только проверить
/rusifikator откат    — вернуть оригинальный интерфейс
```

Или напрямую:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File assets\apply.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File assets\check.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File assets\uninstall.ps1
```

После установки ZCode нужно **полностью** закрыть (трей → «Выйти») и открыть
заново.

## Как это работает

ZCode поставляется только с `zh-CN` и `en-US`; тип локали закрыт в коде, поэтому
новый язык не добавляется. Вместо этого перезаписываются значения английского
каталога внутри `resources/app.asar`, а SHA-256 изменённых файлов в заголовке
asar пересчитываются — иначе Electron откажется их читать.

Пересборка идёт от установленного приложения, поэтому после обновления ZCode
достаточно снова запустить `apply.ps1`: перевод подхватит новый каталог строк, а
незнакомые ключи просто останутся английскими.

## Требования и ограничения

- Windows, ZCode Desktop установлен в `C:\Program Files\ZCode` или
  `%LOCALAPPDATA%\Programs\ZCode`.
- Запись в `app.asar` требует прав администратора — `install.ps1` сам вызывает
  UAC. Без подтверждения окна ничего не меняется.
- Каждое обновление ZCode возвращает оригинальный `app.asar`; перевод нужно
  ставить заново.
- Бэкап оригинала: `%LOCALAPPDATA%\ZCodeRu\app.asar.backup`, логи установки:
  `%LOCALAPPDATA%\ZCodeRu\install.log`.
- `.ps1` обязаны оставаться в UTF-8 **с BOM**: PowerShell 5.1 иначе прочитает
  кириллицу как ANSI и скрипт не разберётся.

## Атрибуция

Перевод — агрегация публичных русификаторов ZCode (AnikLabs/zcode-ru-localization,
xISPx/ZCode_Russifier, plesnev-hash/zcode-ru-linux, mdn77/zcode-translation-ru,
warment/zcode-ru, keasring/zcode-ru-locale, DevGenHub/zcode-rusifikator,
Leostrange/zcode-ru-patcher, nitromir/zcode-ru). Патчер вырос из
`xISPx/ZCode_Russifier` с исправлениями: полное покрытие ключей (включая строки
в кавычках другого типа), экранирование обратных кавычек и `\` в шаблонных
литералах, перевод строк в общем объекте-оверрайде вне каталога.
