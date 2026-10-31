/* zcode-counters v5 — счётчики в строке индикатора «Working», справа от него.
   Надёжная схема: React часто перерисовывает индикатор и выкидывает чужие узлы,
   поэтому полоса — fixed-элемент, который каждый тик встаёт по координатам
   элемента «Working» (getBoundingClientRect). Шрифт копируется у него же.
   Данные: GET http://127.0.0.1:7717/usage/latest (350 мс в работе, 1 с в покое). */
(function () {
  "use strict";

  var ID = "zcode-counters-strip";
  if (document.getElementById(ID)) return;

  var style = document.createElement("style");
  style.textContent =
    "@keyframes zcc-pulse{0%,100%{opacity:.45}50%{opacity:1}}" +
    "@keyframes zcc-spin{from{transform:rotate(0)}to{transform:rotate(360deg)}}" +
    "#" + ID + "{position:fixed;display:none;align-items:center;gap:7px;" +
    "white-space:nowrap;pointer-events:none;opacity:.9;z-index:2147483000;" +
    "transform:translateY(-50%)}" +
    "#" + ID + " .zcc-item{display:inline-flex;align-items:center;gap:4px}" +
    "#" + ID + " .zcc-ico{display:inline-block;animation:zcc-pulse 1.8s ease-in-out infinite}" +
    "#" + ID + " .zcc-ico.spin{animation:zcc-spin 2.4s linear infinite}" +
    "#" + ID + ".live .zcc-ico{animation-duration:.9s}" +
    "#" + ID + ".live .zcc-ico.spin{animation-duration:1.1s}" +
    "#" + ID + " .zcc-sep{opacity:.35}";
  (document.head || document.documentElement).appendChild(style);

  var strip = document.createElement("span");
  strip.id = ID;
  strip.setAttribute("data-zcode-counters", "v5");

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

  var turns = mkItem("⏱", "", "ходов");
  var steps = mkItem("⧉", "", "шагов");
  var speed = mkItem("⚡", "", "ток/с");
  var total = mkItem("▤", "", "ток");
  var cache = mkItem("◔", "spin", "кэш");
  [turns, steps, speed, total, cache].forEach(function (it, i, arr) {
    strip.appendChild(it.wrap);
    if (i < arr.length - 1) strip.appendChild(it.sep);
  });
  (document.body || document.documentElement).appendChild(strip);

  var anchorEl = null;

  // лист с текстом «Working»/«Работает»/«运行中»
  function findWorking() {
    var nodes = document.querySelectorAll("span,div,p,label,button");
    for (var i = nodes.length - 1; i >= 0; i--) {
      var el = nodes[i];
      if (!el || el === strip || el.contains(strip)) continue;
      var t = (el.textContent || "").replace(/\s+/g, " ").trim();
      if (!/^(Работает|Working|运行中)/.test(t)) continue;
      if (el.querySelector("span,div,p,label,button")) continue; // нужен листовой
      var r = el.getBoundingClientRect();
      if (!r.width || !r.height) continue;
      if (r.bottom < window.innerHeight * 0.5) continue; // нижняя зона (над вводом)
      return el;
    }
    return null;
  }

  function copyFont(el) {
    var cs = window.getComputedStyle(el);
    strip.style.fontFamily = cs.fontFamily;
    strip.style.fontSize = cs.fontSize;
    strip.style.fontWeight = cs.fontWeight;
    strip.style.lineHeight = cs.lineHeight;
    strip.style.letterSpacing = cs.letterSpacing;
    strip.style.color = cs.color;
  }

  function place() {
    if (!anchorEl || !document.contains(anchorEl)) {
      anchorEl = findWorking();
      if (!anchorEl) { strip.style.display = "none"; return false; }
      copyFont(anchorEl);
    }
    var r = anchorEl.getBoundingClientRect();
    if (!r.width || !r.height) { strip.style.display = "none"; return false; }

    strip.style.left = Math.round(r.right + 12) + "px";
    strip.style.top = Math.round(r.top + r.height / 2) + "px";
    strip.style.display = "inline-flex";
    return true;
  }

  function fmt(n) {
    if (n >= 1000000) return (n / 1000000).toFixed(1) + " млн";
    if (n >= 1000) return Math.round(n / 1000) + " тыс";
    return String(n || 0);
  }

  function render(u) {
    turns.val.textContent = u.turns + "";
    steps.val.textContent = u.steps + "";
    speed.val.textContent = (u.tokensPerSecond || 0) + "";
    total.val.textContent = fmt(u.tokens && u.tokens.total);
    cache.val.textContent = u.cacheHitPct == null ? "н/д" : u.cacheHitPct.toFixed(1) + "%";
  }

  function tick() {
    var mounted = place();
    if (!mounted) { setTimeout(tick, 700); return; }
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
      .then(function () {
        setTimeout(tick, strip.classList.contains("live") ? 350 : 1000);
      });
  }

  window.addEventListener("resize", place);
  window.addEventListener("scroll", place, true);
  setTimeout(tick, 250);
})();
