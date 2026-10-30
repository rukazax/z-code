# zcode-counters · Token counters

📊 **Counters on the same line as the "Working" spinner:** to the right of it you get
`⏱ 26 ходов · ⧉ 558 шагов · ⚡ 87 ток/с · ▤ 105.9M ток · ◔ 49.8% кэш`, using the
spinner's own font and size, with labels and animated icons. Turns, steps and the total
cover **the current session/task only** and refresh **live**: 350 ms while a turn is
running, 1 s when idle. No session folder/name is shown.

![How it works](../assets/zcode-counters-en.svg)

## Why

ZCode shows no token numbers near the input, though they are already stored —
`turn_usage` (per turn) and `tool_usage` (per tool call) inside the chat database.
This plugin puts those numbers where you look while working.

## How it works

```mermaid
flowchart LR
    D[(usage tables<br/>turn_usage · tool_usage)] --> C[ctxdb daemon<br/>/usage/latest]
    C --> S[DOM overlay<br/>in index.html]
    S --> U[strip above input]
    U -. no daemon .-> X[hidden]
```

- the patch is small: a `<script>` inserted into `out/renderer/index.html` inside `app.asar`;
- the overlay finds the leaf element with "Working"/«Работает» text and inserts itself **right after it**,
  copying the computed font, size and colour — so the line looks native;
- icons are animated: opacity pulse on all of them, rotation on the cache one (`◔`);
- React re-renders "Working" constantly — a `MutationObserver` keeps the insertion alive;
- no React surgery; no daemon → the line stays hidden;
- co-exists with the russifier: their patches do not intersect;
- SHA-256 of changed files recalculated so Electron accepts the archive;
- the original is kept in `%LOCALAPPDATA%\ZCodeCounters\app.asar.backup`.

## What the strip shows

| Metric | Source | Formula |
|---|---|---|
| Turns | `turn_usage` of the current session | `count(*)` |
| Steps | `tool_usage` of the current session | `count(*)` |
| Tokens/s | last turn of the session | `output_tokens / (completed_at − first_token_at)` |
| Σ tokens | session turns | `sum(computed_total_tokens)` |
| Cache % | session turns | `sum(cache_read) / (sum(cache_read) + sum(input))` |
| “Live” | `status='running'` | while a turn runs: 350 ms polling, faster icon animation |

“Current” means the session with the freshest activity (`session.time_updated`). While you
type in this chat, ZCode keeps updating exactly that session, so the numbers belong to the
open task. The unfinished turn is counted too, so values grow as tokens hit the database.
For debugging you can ask for a specific session: `/usage/latest?session=<id>`.

## Install

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File plugins\zcode-counters\assets\apply.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File plugins\zcode-counters\assets\uninstall.ps1
```

Quit ZCode (tray → Quit) and start it again — the strip appears above the input.

## Limits

- Windows only; install paths `C:\Program Files\ZCode` or `%LOCALAPPDATA%\Programs\ZCode`;
- shows the active session only — other task histories are not summed;
- after every ZCode update you have to apply it again;
- if the bundle layout changes, the patcher fails with a clear message and writes nothing.

## License

[MIT](../../LICENSE) (c) 2026 rukazax
