/* zcode-counters v9
   Что делает:
   • вместо спиннера-квадратика и слова «Working»/«Работает» рисует бегущие часики
     (SVG-циферблат с вращающейся стрелкой), таймер остаётся на месте;
   • справа в той же строке — счётчики: ходы · шаги · ток/с · Σ ток · кэш %, шрифт
     копируется у индикатора;
   • все иконки анимированы: часы — вращение стрелки, ходы — медленный оборот,
     шаги — пульс, скорость — вспышки, сумма — «дыхание» масштаба, кэш — вращение.
   Механика: TreeWalker по текстовым узлам + Range-координаты; полоса и «заплатка»
   с часами — fixed-элементы, поэтому переживают перерисовки React.
   Данные: GET http://127.0.0.1:7717/usage/latest (350 мс в работе, 1 с в покое).
   Телеметрия: POST /probe. */
(function () {
  "use strict";

  var ID = "zcode-counters-strip";
  var PATCH_ID = "zcode-counters-clock";
  if (document.getElementById(ID)) return;

  // ---------- телеметрия ----------
  function probe(stage, data) {
    try {
      fetch("http://127.0.0.1:7717/probe", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ stage: stage, w: window.innerWidth, h: window.innerHeight, data: data || null }),
      }).catch(function () {});
    } catch (e) { /* диагностика не должна мешать */ }
  }
  window.addEventListener("error", function (e) {
    probe("error", { message: String(e.message || e.error || "unknown") });
  });

  // ---------- стили и анимации ----------
  var style = document.createElement("style");
  style.textContent =
    "@keyframes zcc-pulse{0%,100%{opacity:.4}50%{opacity:1}}" +
    "@keyframes zcc-spin{from{transform:rotate(0)}to{transform:rotate(360deg)}}" +
    "@keyframes zcc-flash{0%,100%{opacity:.35;filter:saturate(.6)}45%{opacity:1;filter:saturate(1.4)}}" +
    "@keyframes zcc-breathe{0%,100%{transform:scale(1);opacity:.6}50%{transform:scale(1.22);opacity:1}}" +
    "@keyframes zcc-hand{from{transform:rotate(0)}to{transform:rotate(360deg)}}" +
    "#" + ID + "{position:fixed;display:none;align-items:center;gap:7px;white-space:nowrap;" +
    "pointer-events:none;opacity:.9;z-index:2147483000;transform:translateY(-50%)}" +
    "#" + ID + " .zcc-item{display:inline-flex;align-items:center;gap:4px}" +
    "#" + ID + " .zcc-ico{display:inline-block;transform-origin:50% 50%;will-change:transform,opacity}" +
    "#" + ID + " .a-spin{animation:zcc-spin 3.2s linear infinite}" +
    "#" + ID + " .a-pulse{animation:zcc-pulse 1.8s ease-in-out infinite}" +
    "#" + ID + " .a-flash{animation:zcc-flash 1.4s ease-in-out infinite}" +
    "#" + ID + " .a-breathe{animation:zcc-breathe 2.2s ease-in-out infinite}" +
    "#" + ID + ".live .zcc-ico{animation-duration:.8s}" +
    "#" + ID + " .zcc-sep{opacity:.35}" +
    "#" + PATCH_ID + "{position:fixed;display:none;z-index:2147482999;pointer-events:none;" +
    "border-radius:4px;transform:translateY(-50%);overflow:hidden}" +
    "#" + PATCH_ID + " .zcc-hand{transform-origin:12px 12px;animation:zcc-hand 2s linear infinite}";
  (document.head || document.documentElement).appendChild(style);

  var host = document.body || document.documentElement;

  // ---------- «заплатка» с бегущими часами ----------
  var patch = document.createElement("span");
  patch.id = PATCH_ID;
  patch.innerHTML =
    '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
    'stroke-width="2" stroke-linecap="round"><circle cx="12" cy="12" r="9.5"></circle>' +
    '<line class="zcc-hand" x1="12" y1="12" x2="12" y2="6.5"></line></svg>';
  host.appendChild(patch);

  // ---------- полоса счётчиков ----------
  var strip = document.createElement("span");
  strip.id = ID;
  strip.setAttribute("data-zcode-counters", "v9");

  function mkItem(icon, animClass, label) {
    var wrap = document.createElement("span");
    wrap.className = "zcc-item";
    var ico = document.createElement("span");
    ico.className = "zcc-ico " + animClass;
    ico.textContent = icon;
    var val = document.createElement("span");
    val.className = "zcc-val";
    val.textContent = "—";
    var lbl = document.createElement("span");
    lbl.className = "zcc-lbl";
    lbl.textContent = label;
    var sep = document.createElement("span");
    sep.className = "zcc-sep";
    sep.textContent = "·";
    wrap.appendChild(ico);
    wrap.appendChild(val);
    wrap.appendChild(lbl);
    return { wrap: wrap, ico: ico, val: val, lbl: lbl, sep: sep };
  }

  var items = [
    mkItem("⏱", "a-spin", "ходов"),
    mkItem("⧉", "a-pulse", "шагов"),
    mkItem("⚡", "a-flash", "ток/с"),
    mkItem("▤", "a-breathe", "ток"),
    mkItem("◔", "a-spin", "кэш"),
  ];
  items.forEach(function (it, i) {
    strip.appendChild(it.wrap);
    if (i < items.length - 1) strip.appendChild(it.sep);
  });
  host.appendChild(strip);
  probe("loaded", { body: Boolean(document.body) });

  // ---------- поиск индикатора ----------
  var RE_WORKING = /^(Работает|Working|运行中)/;
  var RE_TIMER = /^\d+(?:[.,]\d+)?\s*[cсmsм]$/;

  function translucent(c) {
    return !c || c === "transparent" || /rgba?\(\s*0\s*,\s*0\s*,\s*0\s*,\s*0\s*\)/.test(c);
  }
  function bgOf(el) {
    var cur = el;
    while (cur && cur !== document.documentElement) {
      var bg = window.getComputedStyle(cur).backgroundColor;
      if (!translucent(bg)) return bg;
      cur = cur.parentElement;
    }
    return "rgb(13,17,23)";
  }

  function findTargets() {
    if (!document.body) return null;
    var walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, null);
    var word = null;
    var timer = null;
    var node;
    while ((node = walker.nextNode())) {
      var t = (node.nodeValue || "").replace(/\s+/g, " ").trim();
      if (!t) continue;
      var el = node.parentElement;
      if (!el) continue;
      var rng = document.createRange();
      try { rng.selectNodeContents(node); } catch (e) { continue; }
      var r = rng.getBoundingClientRect();
      if (!r.width || !r.height) continue;
      if (r.bottom < window.innerHeight * 0.45) continue;

      if (RE_WORKING.test(t) && (!word || r.bottom > word.rect.bottom)) {
        word = { node: node, rect: r, fontEl: el };
      } else if (RE_TIMER.test(t) && (!timer || r.right > timer.rect.right)) {
        timer = { node: node, rect: r, fontEl: el };
      }
    }
    if (!word && !timer) return null;
    return { word: word, timer: timer };
  }

  function copyFont(target, el) {
    var cs = window.getComputedStyle(el);
    target.style.fontFamily = cs.fontFamily;
    target.style.fontSize = cs.fontSize;
    target.style.fontWeight = cs.fontWeight;
    target.style.lineHeight = cs.lineHeight;
    target.style.letterSpacing = cs.letterSpacing;
    target.style.color = cs.color;
  }

  var mountedOnce = false;
  var noAnchorReported = false;

  function place() {
    var t = findTargets();
    if (!t) {
      strip.style.display = "none";
      patch.style.display = "none";
      if (!noAnchorReported) { noAnchorReported = true; probe("no-anchor"); }
      return false;
    }

    var anchor = (t.timer && (!t.word || t.timer.rect.right >= t.word.rect.right)) ? t.timer : t.word;

    if (t.word) {
      var w = t.word.rect;
      var left = Math.max(0, w.left - 26); // накрываем и квадратик-спиннер слева
      patch.style.background = bgOf(t.word.fontEl);
      patch.style.left = Math.round(left) + "px";
      patch.style.top = Math.round(w.top + w.height / 2) + "px";
      patch.style.width = Math.round(w.right - left + 4) + "px";
      patch.style.height = Math.round(Math.max(18, w.height + 4)) + "px";
      patch.style.display = "flex";
      patch.style.alignItems = "center";
      patch.style.justifyContent = "flex-start";
      patch.style.paddingLeft = "3px";
      patch.style.boxSizing = "border-box";
      copyFont(patch, t.word.fontEl);
    } else {
      patch.style.display = "none";
    }

    copyFont(strip, anchor.fontEl);
    strip.style.left = Math.round(anchor.rect.right + 12) + "px";
    strip.style.top = Math.round(anchor.rect.top + anchor.rect.height / 2) + "px";
    strip.style.display = "inline-flex";

    if (!mountedOnce) {
      mountedOnce = true;
      probe("anchor", {
        right: Math.round(anchor.rect.right),
        top: Math.round(anchor.rect.top),
        hasWord: Boolean(t.word),
        hasTimer: Boolean(t.timer),
      });
    }
    noAnchorReported = false;
    return true;
  }

  // ---------- данные ----------
  function fmt(n) {
    if (n >= 1000000) return (n / 1000000).toFixed(1) + " млн";
    if (n >= 1000) return Math.round(n / 1000) + " тыс";
    return String(n || 0);
  }

  function render(u) {
    items[0].val.textContent = u.turns + "";
    items[1].val.textContent = u.steps + "";
    items[2].val.textContent = (u.tokensPerSecond || 0) + "";
    items[3].val.textContent = fmt(u.tokens && u.tokens.total);
    items[4].val.textContent = u.cacheHitPct == null ? "н/д" : u.cacheHitPct.toFixed(1) + "%";
  }

  function tick() {
    var ok = place();
    if (!ok) { setTimeout(tick, 500); return; }
    fetch("http://127.0.0.1:7717/usage/latest", { cache: "no-store" })
      .then(function (res) { return res.ok ? res.json() : null; })
      .then(function (j) {
        var u = j && j.usage;
        if (!u || !u.ok || u.empty) { strip.style.opacity = "0.35"; return; }
        strip.style.opacity = "0.9";
        if (u.running) strip.classList.add("live"); else strip.classList.remove("live");
        render(u);
      })
      .catch(function () { strip.style.opacity = "0.35"; })
      .then(function () { setTimeout(tick, strip.classList.contains("live") ? 350 : 900); });
  }

  window.addEventListener("resize", place);
  window.addEventListener("scroll", place, true);
  setTimeout(tick, 250);
})();
