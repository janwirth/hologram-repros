# Hologram repro: the boot render removes nodes other tools append to `<head>` and `<body>`

Minimal reproduction of [bartblast/hologram#1380](https://github.com/bartblast/hologram/issues/1380),
forked from [hologram_skeleton](https://github.com/bartblast/hologram_skeleton), on
Hologram 0.12.2 from hex. Live at https://hologram-head-tail-repro.jan-wirth.dev.

## The bug

Dev tools add tags to every HTML response by appending them to the end of
`<head>` and `<body>`. Tidewave appends `<meta name="tidewave:config">` and
its toolbar `<script>` to `<head>`. Phoenix LiveReloader appends an
`<iframe>` to `<body>`.

Hologram's first client-side render removes every node in `<head>` and
`<body>` that it did not render itself. `Vdom.mirror` (`assets/js/vdom.mjs`)
mirrors DOM nodes past the rendered children as vnodes of their own, so the
patch removes them. Tidewave's toolbar then fails with `Missing <meta
name="tidewave:config"> tag on the page`, and live reload stops working.

This app has no Tidewave. `lib/hologram_skeleton_web/plugs/tool_injector.ex`
is a plug that does what Tidewave does: in `register_before_send` it appends
to every HTML response

- `<meta name="x-tool:config">` and an inline `<script>` to the end of `<head>`,
- a blue badge `<div>` to the end of `<body>`.

The endpoint also runs Phoenix.LiveReloader, which appends its `<iframe>`.

The injected script checks for all four nodes at `DOMContentLoaded`, then
again 1.5 s after `load`, when Hologram has booted. It writes the result to
a fixed banner at the top of the page and to the console. The page also has
a counter button, to show that Hologram itself works.

- **Expected**: green banner, `OK - nodes kept.`, blue badge in the corner,
  live reload works.
- **Actual**: red banner, `BUG - Hologram removed appended nodes.`, the badge
  is gone, and the console shows:

  ```
  [x-tool] before Hologram boot: meta present, head script present, body badge present, LiveReloader iframe present
  Hologram: page rendered in 41 ms
  [x-tool] 1.5 s after load: meta MISSING, head script MISSING, body badge MISSING, LiveReloader iframe MISSING
  ```

The counter still increments: the page works, but the tools' nodes are gone.

## Run it

```bash
mix setup
HOLOGRAM_START=1 mix phx.server
```

Open http://localhost:4000 and wait two seconds: the banner turns red.

Or with Docker, as on the dev box: `docker compose up -d --build`, then open
http://127.0.0.1:4102.

## Fix

Fork commit, with tests:
[janwirth/hologram@9f0fb5f](https://github.com/janwirth/hologram/commit/9f0fb5f376feb0d7c7d64165d625df5c446c7685).
`Vdom.mirror` keeps the tail of `<head>` and `<body>` out of the vdom, except
scripts whose `src` starts with `/hologram/` (the runtime's own bundles, which
the patch may remove once they have run). What the patch never sees, it
neither removes nor moves. The `assets/js/vdom.mjs` part applies cleanly to
0.12.2; with it, this page shows the green banner.
