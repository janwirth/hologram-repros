// Measures what Hologram does after each button click and prints it on the page.
//
// - Render time: Hologram's own number. Hologram.render() logs
//   "Hologram: page rendered in <n> ms" around renderPage + patch; this script
//   catches that log line.
// - Card templates evaluated: the renderer evaluates a component by calling its
//   template/0, so wrapping HologramSkeleton.Card's template/0 counts how many
//   of the 300 cards were evaluated during the render.
(() => {
  let current = null;
  let cardEvaluations = 0;
  let wrapped = false;
  const results = [];

  function wrapCardTemplate() {
    // The module object is a Proxy that raises on unknown keys, so the
    // "already wrapped" flag lives here, not on the module.
    const mod = globalThis.Elixir_HologramSkeleton_Card;
    if (!mod || wrapped) return;
    const original = mod["template/0"];
    mod["template/0"] = function (...args) {
      cardEvaluations++;
      return original.apply(this, args);
    };
    wrapped = true;
  }

  document.addEventListener(
    "click",
    (event) => {
      const button = event.target.closest("button[id]");
      if (!button) return;
      wrapCardTemplate();
      cardEvaluations = 0;
      current = {label: button.textContent.trim(), renders: []};
      results.unshift(current);
    },
    true,
  );

  const log = console.log;
  console.log = function (...args) {
    log.apply(this, args);
    if (args[0] !== "Hologram: page rendered in" || !current) return;
    current.renders.push({time: String(args[1]), cards: cardEvaluations});
    cardEvaluations = 0;
    show();
  };

  function show() {
    const out = document.getElementById("timings");
    if (!out) return;
    out.textContent = results
      .slice(0, 8)
      .map((r) =>
        r.renders
          .map((x) => `${r.label}: ${x.time} render, ${x.cards}/300 card templates evaluated`)
          .join("\n"),
      )
      .join("\n");
    window.demoResults = results;
  }
})();
