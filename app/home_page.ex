defmodule HologramSkeleton.HomePage do
  @moduledoc """
  Repro for bartblast/hologram#1673: clicks lost before Hologram's first render: the server's HTML shows a
  working counter, but its button has no listener until the runtime and the page
  bundle have loaded and rendered. HologramSkeleton.SlowBundles holds those
  bundles back so the window is long enough to click in.
  """
  use Hologram.Page

  route "/"

  layout HologramSkeleton.DefaultLayout

  def init(_params, component, _server) do
    # delay_ms/0 reads the env, which only the server can.
    put_state(component, count: 0, delay_ms: HologramSkeleton.SlowBundles.delay_ms())
  end

  def action(:increment, _params, component) do
    put_state(component, :count, component.state.count + 1)
  end

  def template do
    ~HOLO"""
    <main>
      <h1>Hologram: clicks before the first render are lost</h1>
      <p>
        The server holds Hologram's JS bundles back for {@delay_ms} ms,
        like a slow connection does with a large bundle. The page looks ready at once, but the
        button has no listener until the runtime has rendered.
      </p>
      <ol>
        <li>Reload the page.</li>
        <li>Click <b>+1</b> a few times right away.</li>
        <li>Wait for the green line below. It counts your clicks; the count shows how many arrived.</li>
      </ol>
      <p class="counter">
        Count: <span id="count">{@count}</span>
        <button type="button" id="increment" $click="increment">+1</button>
      </p>
      <p id="report"></p>
      <p>Issue: <a href="https://github.com/bartblast/hologram/issues/1673">bartblast/hologram#1673</a>.</p>
    </main>
    """
  end
end
