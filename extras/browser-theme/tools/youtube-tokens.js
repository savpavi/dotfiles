// YouTube names most of its colour variables with build-generated hashes (--t3e41d7b17b187f69).
// This prints the block between the "generated" markers of styles/youtube.user.css.
// Run it in the DevTools console on any youtube.com page when the style stops matching
// (the hashes changed), then replace the block with the output.
//
// A hashed variable has no readable name, so its role is read from its pair of values in
// YouTube's own light and dark themes: white-on-light / near-black-on-dark is a page
// background, the reverse is text, and so on. Pairs that match no role are left alone.
(() => {
  const light = {}, dark = {};
  for (const sheet of document.styleSheets) {
    let rules;
    try { rules = sheet.cssRules; } catch (e) { continue; }
    for (const r of rules) {
      const into = r.selectorText === "[light]" ? light : r.selectorText === "[dark]" ? dark : null;
      if (!into) continue;
      for (const p of r.style) {
        if (/^--t[0-9a-f]{12,}$/.test(p)) into[p] = r.style.getPropertyValue(p).trim().replace(/\s+/g, "");
      }
    }
  }
  const alpha = v => { const m = /^rgba\((\d+),(\d+),(\d+),([\d.]+)\)$/.exec(v); return m && { c: m[1] + "," + m[2] + "," + m[3], a: +m[4] }; };
  const pct = a => Math.round(Math.max(a, 0.06) * 100) + "%";
  const exact = {
    "#fff|#0f0f0f": "var(--dwl-bg)", "#fff|#212121": "var(--dwl-bg2)", "#fff|#282828": "var(--dwl-bg2)",
    "#f9f9f9|#181818": "var(--dwl-raised)",
    "#0f0f0f|#f1f1f1": "var(--dwl-fg)", "#0f0f0f|#e6e6e6": "var(--dwl-fg)", "#000|#fff": "var(--dwl-fg)",
    "#606060|#aaa": "var(--dwl-muted)", "#909090|#717171": "var(--dwl-faint)", "#717171|#909090": "var(--dwl-faint)",
    "#e6e6e6|#0f0f0f": "var(--dwl-bg)",
    "#272727|#d9d9d9": "var(--dwl-muted)", "#3f3f3f|#e5e5e5": "var(--dwl-muted)", "#3f3f3f|#d9d9d9": "var(--dwl-muted)",
    "#333|#f1f1f1": "var(--dwl-muted)", "#181818|#ccc": "var(--dwl-muted)",
    "#d9d9d9|#272727": "var(--dwl-hover)", "#e5e5e5|#3f3f3f": "var(--dwl-border)",
    "#065fd4|#3ea6ff": "var(--dwl-accent)", "#3ea6ff|#065fd4": "var(--dwl-accent)", "#263850|#def1ff": "var(--dwl-accent)",
    "#0556bf|#65b8ff": "var(--dwl-accent2)",
    "#def1ff|#263850": "color-mix(in srgb, var(--dwl-accent) 18%, transparent)",
    "#c30027|#f57": "var(--dwl-red)", "#f57|#c30027": "var(--dwl-red)", "#f57|#f03": "var(--dwl-red)",
  };
  const out = [];
  for (const name of Object.keys(light).sort()) {
    const l = light[name], d = dark[name];
    if (!d) continue;
    let v = exact[l + "|" + d];
    const la = alpha(l), da = alpha(d);
    if (!v && la && da) {
      if (la.c === "0,0,0" && da.c === "255,255,255") v = `color-mix(in srgb, var(--dwl-fg) ${pct(Math.max(la.a, da.a))}, transparent)`;
      else if (la.c === "255,255,255" && da.c === "0,0,0") v = `color-mix(in srgb, var(--dwl-bg) ${pct(Math.max(la.a, da.a))}, transparent)`;
      else if (la.c === "255,255,255" && da.c === "15,15,15") v = `color-mix(in srgb, var(--dwl-bg) ${pct(Math.max(la.a, da.a))}, transparent)`;
    }
    if (v) out.push(`    ${name}: ${v};`);
  }
  const text = out.join("\n");
  console.log(text);
  return text;
})();
