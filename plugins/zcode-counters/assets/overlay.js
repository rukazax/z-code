/* zcode-counters v4 — счётчики в одну строку с индикатором «Working».
   Справа от бегунка: иконки + значения + подписи как в DeepSeek Harness:
   «ходов», «шагов», «ток/с», «ток», «кэш».
   Данные: GET http://127.0.0.1:7717/usage/latest (350 мс в работе, 1 с в покое). */
(function () {
  "use strict";

  var ID = "zcode-counters-strip";
  if (document.getElementById(ID)) return;

  var style = document.createElement("style");
  style.textContent =
    "@keyframes zcc-pulse{0%,100%{opacity:.45}50%{opacity:1}}" +
    "@keyframes zcc-spin{from{transform:rotate(0)}to{transform:rotate(360deg)}}" +
    "#" + ID + "{display:none;align-items:center;gap:8px;margin-left:10px;" +
    "white-space:nowrap;vertical-align:middle;pointer-events:none;opacity:.85}" +
    "#" + ID + " .zcc-item{display:inline-flex;align-items:center;gap:4px}" +
    "#" + ID + " .zcc-ico{display:inline-block;animation:zcc-pulse 1.8s ease-in-out infinite}" +
    "#" + ID + " .zcc-ico.spin{animation:zcc-spin 2.4s linear infinite}" +
    "#" + ID + ".live .zcc-ico{animation-duration:.9s}" +
    "#" + ID + ".live .zcc-ico.spin{animation-duration:1.1s}" +
    "#" + ID + " .zcc-sep{opacity:.35}";
  (document.head || document.documentElement).appendChild(style);

  var strip = document.createElement("span");
  strip.id = ID;
  strip.setAttribute("data-zcode-counters", "v4");

  function mkItem(iconChar, cls, label) {
    var wrap = document.createElement("span");
    wrap.className = "zcc-item";
    var ico = document.createElement("span");
    ico.className = "zcc-ico" + (cls ? " " + cls : "");
    ico.textContent = iconChar;
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

  // иконки и подписи как в DeepSeek Harness: ходов · шагов · ток/с · ток · кэш
  var turns = mkItem("⏱", "", "ходов");
  var steps = mkItem("⧉", "", "шагов");
  var speed = mkItem("⚡", "", "ток/с");
  var total = mkItem("▤", "", "ток");
  var cache = mkItem("◔", "spin", "кэш");

  [turns, steps, speed, total, cache].forEach(function (it, i, arr) {
    strip.appendChild(it.wrap);
    if (i < arr.length - 1) strip.appendChild(it.sep);
  });

  var hostFound = null;

  // листовой элемент, который прямо сейчас показывает «Working <время>»
  function findWorking() {
    var nodes = document.querySelectorAll("span,div,p,label,button");
    for (var i = nodes.length - 1; i >= 0; i--) {
      var el = nodes[i];
      if (!el || el === strip || el.contains(strip) || strip.contains(el)) continue;
      var t = (el.textContent || "").trim();
      if (!t || t.length > 40) continue;
      if (!/^(Работает|Working|运行中)/.test(t)) continue;
      if (el.querySelector("span,div,p,label,button")) continue; // нужен листовой
      // отсекаем меню/скрытые
      var r = el.getBoundingClientRect();
      if (!r.width || !r.height) continue;
      return el;
    }
    return null;
  }

  function applyFont(el) {
    var cs = window.getComputedStyle(el);
    strip.style.fontFamily = cs.fontFamily;
    strip.style.fontSize = cs.fontSize;
    strip.style.fontWeight = cs.fontWeight;
    strip.style.lineHeight = cs.lineHeight;
    strip.style.letterSpacing = cs.letterSpacing;
    strip.style.color = cs.color;
    strip.style.opacity = "0.85";
  }

  function attach() {
    if (hostFound && document.contains(hostFound) && hostFound.parentNode) return true;
    var w = findWorking();
    if (!w) { strip.style.display = "none"; hostFound = null; return false; }
    hostFound = w;
    applyFont(w);
    w.parentNode.insertBefore(strip, w.nextSibling);
    return true;
  }

  var fmt = function (n) {
    if (n >= 1000000) return (n / 1000000).toFixed(1) + " млн";
    if (n >= 1000) return Math.round(n / 1000) + " тыс";
    return String(n || 0);
  };

  function render(u) {
    turns.val.textContent = u.turns + "";
    steps.val.textContent = u.steps + "";
    speed.val.textContent = (u.tokensPerSecond || 0) + "";
    total.val.textContent = fmt(u.tokens && u.tokens.total);
    cache.val.textContent = u.cacheHitPct == null ? "н/д" : u.cacheHitPct.toFixed(1) + "%";
  }

  function tick() {
    var ok = attach();
    if (!ok) return;
    fetch("http://127.0.0.1:7717/usage/latest", { cache: "no-store" })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (j) {
        if (!j || !j.ok || !j.usage || !j.usage.ok || j.usage.empty) {
          strip.style.display = "none";
          hostFound = null;
          return;
        }
        render(j.usage);
        if (j.usage.running) strip.classList.add("live");
        else strip.classList.remove("live");
        strip.style.display = "inline-flex";
      })
      .catch(function () {
        strip.style.display = "none";
        hostFound = null;
      });
  }

  // React перерисовывает «Working» часто — просто поддерживаем вставку живой
  var mo = new MutationObserver(function () { attach(); });
  mo.observe(document.documentElement, { childList: true, subtree: true });

  // почти непрерывно: пока идёт ход — 350 мс, в покое — 1 с
  (function loop() {
    tick();
    setTimeout(loop, strip.classList.contains("live") ? 350 : 1000);
  })();
})();
