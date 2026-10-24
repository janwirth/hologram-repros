defmodule HologramSkeleton.HomePage do
  @moduledoc """
  Reproduction: a live reload pass fails when a file in the static dir
  disappears while Hologram scans it. On 0.12.2 the scan runs inside the
  `Hologram.LiveReload` GenServer, which crashes, and the asset path registry
  is left empty: every page answers 500 (`Hologram.AssetNotFoundError` for
  `hologram/runtime.js`) until the next successful pass.

  `/repro/trigger` (see `HologramSkeletonWeb.Repro`) puts a dangling symlink
  in `priv/static/assets` - a chunk file that is listed but gone by the time
  it is checked, as when esbuild replaces its chunks - and bumps `@revision`
  below, so the page bundle changes and live reload runs a pass.
  """
  use Hologram.Page

  route "/"

  layout HologramSkeleton.DefaultLayout

  # Bumped by /repro/trigger and /repro/reset.
  @revision 6

  def init(_params, component, _server) do
    put_state(component, count: 0, revision: @revision)
  end

  def action(:increment, _params, component) do
    put_state(component, :count, component.state.count + 1)
  end

  def template do
    ~HOLO"""
    <main style="font-family: sans-serif; max-width: 40rem; margin: 4rem auto; line-height: 1.5;">
      <h1>Hologram: live reload asset scan race</h1>
      <p>
        Revision {@revision}. If you can read this, the asset path registry is intact;
        the number below changes on click.
      </p>
      <p id="count" style="font-size: 3rem; margin: 1rem 0;">{@count}</p>
      <p><button type="button" $click="increment">+1</button></p>
      <p>
        <a href="/repro/trigger">Trigger the race</a>
        (adds a vanished chunk file to <code>priv/static/assets</code> and edits this page;
        the pass crashes and this page answers 500 until a reset)
        · <a href="/repro/reset">Reset</a> (clean pass)
      </p>
      <p style="color: #666; font-size: 0.9rem;">
        Issue: <a href="https://github.com/bartblast/hologram/issues/1379">bartblast/hologram#1379</a>
      </p>
    </main>
    """
  end
end
