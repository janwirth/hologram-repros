# Hologram repros

Live reproductions for [bartblast/hologram](https://github.com/bartblast/hologram) issues.
Each repro is its own branch, a [hologram_skeleton](https://github.com/bartblast/hologram_skeleton)
fork that runs in dev mode with `docker compose up` (or `mix setup && HOLOGRAM_START=1 mix phx.server`).
The branch README has the bug, the steps and what to expect.

| Issue | Branch | Live |
|---|---|---|
| [#1379](https://github.com/bartblast/hologram/issues/1379) live reload asset scan crashes on a vanished file | [`1379-live-reload-race`](https://github.com/janwirth/hologram-repros/tree/1379-live-reload-race) | https://hologram-live-reload-race-repro.jan-wirth.dev |
| [#1380](https://github.com/bartblast/hologram/issues/1380) client render removes nodes appended to head and body | [`1380-head-tail`](https://github.com/janwirth/hologram-repros/tree/1380-head-tail) | https://hologram-head-tail-repro.jan-wirth.dev |
| [#1381](https://github.com/bartblast/hologram/issues/1381) every action re-renders every component | [`1381-rerender`](https://github.com/janwirth/hologram-repros/tree/1381-rerender) | https://hologram-rerender-repro.jan-wirth.dev |
| [#1290](https://github.com/bartblast/hologram/issues/1290) long `in` guard makes the bundle unparseable (closed) | [`1290-nested-guard`](https://github.com/janwirth/hologram-repros/tree/1290-nested-guard) | https://hologram-nested-guard-repro.jan-wirth.dev |

The live apps run on a dev box behind a Cloudflare tunnel. They are throwaway
and may go away once an issue is closed.
