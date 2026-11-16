// Counts the clicks on +1 from the moment the page is parsed, in the capture phase, so it sees
// the clicks Hologram has no listener for yet. Once Hologram logs its first "page rendered" line
// it reports them next to the count, then keeps the report up to date. The report is written only
// after the first render: Hologram's first patch would remove text written before it.
(() => {
  let clicks = 0;
  let rendered = false;
  let clicksBeforeRender = 0;
  // True for the rest of the task that logged the first render, where a runtime that replays
  // early clicks dispatches them again: those were counted already.
  let replaying = false;

  function report() {
    const count = document.getElementById("count").textContent.trim();
    const el = document.getElementById("report");
    el.className = "ok";
    el.textContent =
      `You clicked +1 ${clicks} time(s), ${clicksBeforeRender} of them before Hologram rendered. ` +
      `Count: ${count}.`;
  }

  document.addEventListener(
    "click",
    (event) => {
      if (replaying || !event.target.closest("#increment")) return;
      clicks++;
      if (!rendered) clicksBeforeRender++;
      // After the action has rendered.
      else setTimeout(report, 100);
    },
    true,
  );

  const log = console.log;
  console.log = function (...args) {
    log.apply(this, args);
    if (!rendered && String(args[0]).includes("page rendered")) {
      rendered = true;
      replaying = true;
      setTimeout(() => (replaying = false));
      // Give a replay (the fix) its render first.
      setTimeout(report, 300);
    }
  };
})();
