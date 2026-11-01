/* zcode-counters v17 — строка счётчиков ВНУТРИ поля ввода:
   прижата к низу композера, растянута по его ширине, пять показателей равномерно.
   Внутри бокса резервируем отступ снизу, чтобы не наезжать на текст.
   Слово «Working» скрыто; анимация иконок — только пока меняются значения. */
(function () {
  "use strict";
  var ID = "zcode-counters-strip";
  if (document.getElementById(ID)) return;

  var css = document.createElement("style");
  css.textContent =
    "@keyframes zcc-pulse{0%,100%{opacity:.4}50%{opacity:1}}" +
    "@keyframes zcc-spin{from{transform:rotate(0)}to{transform:rotate(360deg)}}" +
    "@keyframes zcc-flash{0%,100%{opacity:.35}45%{opacity:1}}" +
    "@keyframes zcc-breathe{0%,100%{transform:scale(1);opacity:.6}50%{transform:scale(1.2);opacity:1}}" +
    "#" + ID + "{position:absolute;left:0;right:0;bottom:2px;display:none;" +
    "grid-template-columns:repeat(7,1fr);align-items:center;box-sizing:border-box;" +
    "padding:3px 14px 2px;pointer-events:none;z-index:5;" +
    "border-top:1px solid rgba(255,255,255,.055);" +
    "font:11px/1.25 -apple-system,Segoe UI,sans-serif;color:#8b949e;" +
    "font-variant-numeric:tabular-nums;letter-spacing:.15px}" +
    "#" + ID + " .i{display:inline-flex;align-items:center;justify-content:center;gap:5px;white-space:nowrap}" +
    "#" + ID + " .v{color:#c9d1d9;font-weight:600}" +
    "#" + ID + " .l{color:#8b949e;opacity:.62}" +
    "#" + ID + " svg{width:1em;height:1em;flex:none;opacity:.75}" +
    "#" + ID + " .a-spin{animation:zcc-spin 3.2s linear infinite}" +
    "#" + ID + " .a-pulse{animation:zcc-pulse 1.8s ease-in-out infinite}" +
    "#" + ID + " .a-flash{animation:zcc-flash 1.4s ease-in-out infinite}" +
    "#" + ID + " .a-breathe{animation:zcc-breathe 2.2s ease-in-out infinite}" +
    "#" + ID + " .anim{animation-play-state:paused}" +
    "#" + ID + ".live .anim{animation-play-state:running;animation-duration:.9s}";
  (document.head || document.documentElement).appendChild(css);

  var SVG = {
    turns: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="13" r="8"/><path d="M12 9v4l3 2M9 3h6"/></svg>',
    steps: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="4" y="4" width="6" height="6"/><rect x="14" y="14" width="6" height="6"/><path d="M10 7h4v10"/></svg>',
    speed: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M13 2 4 14h6l-1 8 9-12h-6l1-8z"/></svg>',
    total: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><ellipse cx="12" cy="6" rx="8" ry="3"/><path d="M4 6v12c0 1.7 3.6 3 8 3s8-1.3 8-3V6"/><path d="M4 12c0 1.7 3.6 3 8 3s8-1.3 8-3"/></svg>',
    wallet: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="6" width="18" height="13" rx="2"/><path d="M3 10h18M16 15h2"/></svg>',
    cache: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M12 3v9l6 3"/></svg>',
  };

  var strip = document.createElement("div");
  strip.id = ID;
  var vals = [];
  function add(icon, anim, label) {
    var el = document.createElement("span");
    el.className = "i";
    el.innerHTML = '<span class="anim ' + anim + '">' + icon + "</span>" +
      '<span class="v">—</span><span class="l">' + label + "</span>";
    strip.appendChild(el);
    vals.push(el.querySelector(".v"));
  }
  add(SVG.turns, "a-spin", "ходов");
  add(SVG.steps, "a-pulse", "шагов");
  add(SVG.speed, "a-flash", "ток/с");
  add(SVG.total, "a-breathe", "ток");
  add(SVG.cache, "a-spin", "кэш");
  add(SVG.wallet, "a-spin", "баланс");
  add(SVG.cache, "a-spin", "модель");
  (document.body || document.documentElement).appendChild(strip);

  // контейнер композера: рамка + шире самого textarea
  function hostOf(el) {
    var r = el.getBoundingClientRect();
    var cur = el;
    for (var i = 0; i < 5 && cur && cur.parentElement; i++) {
      cur = cur.parentElement;
      var cs = window.getComputedStyle(cur);
      var br = cur.getBoundingClientRect();
      if (br.width > r.width * 1.02 && (cs.borderRadius !== "0px" || cs.borderTopWidth !== "0px")) return cur;
    }
    return el.parentElement;
  }

  function reserve(host) {
    if (host.dataset.zccReserved) return;
    var pb = parseFloat(window.getComputedStyle(host).paddingBottom) || 0;
    host.style.paddingBottom = (pb + 22) + "px";
    host.dataset.zccReserved = "1";
    if (window.getComputedStyle(host).position === "static") host.style.position = "relative";
  }

  function hideWorking() {
    try {
      var w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null);
      var n;
      while ((n = w.nextNode())) {
        if (/^(Работает|Working|运行中)$/.test((n.nodeValue || "").trim()) && n.parentElement) {
          n.parentElement.style.visibility = "hidden";
        }
      }
    } catch (e) { /* не критично */ }
  }

  function place() {
    var el = document.querySelector('textarea, [contenteditable="true"]');
    if (!el) { strip.style.display = "none"; return false; }
    var host = hostOf(el);
    if (!host) { strip.style.display = "none"; return false; }
    reserve(host);
    if (strip.parentElement !== host) host.appendChild(strip);
    strip.style.display = "grid";
    return true;
  }

  function fmt(n) {
    if (n >= 1e6) return (n / 1e6).toFixed(1) + " млн";
    if (n >= 1000) return Math.round(n / 1000) + " тыс";
    return String(n || 0);
  }

  var lastKey = "";
  function tick() {
    place();
    fetch("http://127.0.0.1:7717/usage/latest", { cache: "no-store" })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (j) {
        var u = j && j.usage;
        if (!u || !u.ok || u.empty) { strip.classList.remove("live"); return; }
        var key = [u.turns, u.steps, u.tokensPerSecond, u.tokens && u.tokens.total, u.cacheHitPct].join("|");
        if (key !== lastKey) { lastKey = key; strip.classList.add("live"); }
        else { strip.classList.remove("live"); }
        vals[0].textContent = u.turns;
        vals[1].textContent = u.steps;
        vals[2].textContent = u.tokensPerSecond || 0;
        vals[3].textContent = fmt(u.tokens && u.tokens.total);
        vals[4].textContent = u.cacheHitPct == null ? "н/д" : u.cacheHitPct.toFixed(1) + "%";
                                        vals[5].textContent = u.balance && u.balance.amount != null ? "$" + Number(u.balance.amount).toFixed(2) : "—";
        vals[6].textContent = u.modelPct == null ? "—" : u.modelPct + "%";
              })
      .catch(function () { strip.classList.remove("live"); })
      .then(function () { setTimeout(tick, 400); });
  }

  setTimeout(tick, 400);
})();


