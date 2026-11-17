# Hologram repro: clicks before the first render are lost

Minimal repro for [bartblast/hologram#1673](https://github.com/bartblast/hologram/issues/1673): clicks and keystrokes that Hologram drops while the page loads,
forked from [hologram_skeleton](https://github.com/bartblast/hologram_skeleton), on Hologram 0.12.9.
Live at https://hologram-early-click-repro.jan-wirth.dev.

## The problem

The server's HTML looks finished, but it has no listeners until the runtime and the page bundle
have loaded and the first render has run. A click in that time reaches nothing and is lost.

`app/home_page.ex` is a counter: `#count` and a **+1** button with `$click="increment"`.
`HologramSkeleton.SlowBundles` (a plug before `Plug.Static`) holds every `/hologram/*.js`
response back for 4 s (`DELAY_MS`), standing in for a large bundle on a slow connection.
`priv/static/early.js` counts the clicks on **+1** from the start and, after Hologram's first
`page rendered` log, prints them next to the count.

## Run it

```bash
docker compose up -d --build
```

Open http://localhost:4104, click **+1** a few times right after the page loads, and wait for
the green line. Or let Lightpanda click once before the render:

```bash
bin/repro
```

## What happens

```
You clicked +1 3 time(s), 3 of them before Hologram rendered. Count: 0.
```

`bin/repro` prints the same with 1 click and count 0. With the early click replayed
([janwirth/hologram@142e4c0](https://github.com/janwirth/hologram/commit/142e4c083)) the count is 1.
