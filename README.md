# Hologram demo: every action re-renders every component

Minimal demo for [bartblast/hologram#1381](https://github.com/bartblast/hologram/issues/1381),
forked from [hologram_skeleton](https://github.com/bartblast/hologram_skeleton), on Hologram 0.12.2.
Live at https://hologram-rerender-repro.jan-wirth.dev.

## The problem

Every action re-renders the whole page on the client. `Hologram.render()`
calls `Renderer.renderPage()`, which evaluates every component template from
the page down, even when a component's props, state, slots and context are
unchanged. Snabbdom then diffs the full tree.

`app/home_page.ex` renders 300 stateless `HologramSkeleton.Card` components
(their only prop, `index`, never changes) and one small `HologramSkeleton.Panel`
with one boolean prop. Two buttons run client-side actions:

```elixir
# Returns the page unchanged.
def action(:noop, _params, component), do: component

# Flips one boolean that only the panel reads.
def action(:toggle, _params, component) do
  put_state(component, :open, !component.state.open)
end
```

`priv/static/demo.js` prints one line per render on the page:

- the render time, taken from Hologram's own `Hologram: page rendered in` log
  (`Hologram.render()`, around `renderPage` and the patch);
- how many card templates the render evaluated, counted by wrapping
  `HologramSkeleton.Card`'s `template/0`, which the renderer calls once per
  evaluated component.

## Run it

```bash
docker compose up -d --build
```

Or without Docker:

```bash
mix setup
HOLOGRAM_START=1 PORT=4103 mix phx.server
```

Open http://localhost:4103, click **No-op action** a few times, then
**Toggle panel**.

## What happens

Every click evaluates all 300 card templates, for both buttons:

```
No-op action: 95 ms render, 300/300 card templates evaluated
Toggle panel: 61 ms render, 300/300 card templates evaluated
```

Measured in headless Chrome 124 through CDP (real mouse events), dev build,
15 clicks per button, one render per click:

| Action | Render (median) | Range | Card templates evaluated |
|---|---|---|---|
| No-op action | 74 ms | 46-136 ms | 300 / 300 |
| Toggle panel | 61 ms | 45-88 ms | 300 / 300 |

The dev build logs every function call to the console, which adds to these
times. The issue's jsdom benchmark without dev logging has the same shape:
47 ms for a no-op render, 40 ms for a one-prop toggle.

## Expected

A no-op action evaluates no template. Toggling the panel evaluates the page
and the panel, not the 300 cards whose inputs did not change.

## Fix

Proposed on the fork: branch
[`janwirth/hologram` `skip-unchanged-components`](https://github.com/janwirth/hologram/tree/skip-unchanged-components)
at [f43502714](https://github.com/janwirth/hologram/commit/f43502714). The
renderer caches each component's last output by its place in the tree and
reuses it when the module, props, slots, context and nested stateful state are
unchanged. In the issue's benchmark a no-op render drops from 47 ms to 6 ms.
