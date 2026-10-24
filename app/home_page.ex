defmodule HologramSkeleton.HomePage do
  @moduledoc """
  Demo for bartblast/hologram#1381: every action re-renders the whole page on
  the client, including 300 stateless cards whose props never change.
  """
  use Hologram.Page

  alias HologramSkeleton.{Card, Panel}

  route "/"

  layout HologramSkeleton.DefaultLayout

  @cards Enum.to_list(1..300)

  def init(_params, component, _server) do
    put_state(component, open: false, cards: @cards)
  end

  # Returns the component unchanged: state, props and slots are all the same.
  def action(:noop, _params, component), do: component

  # Flips one boolean that only the small panel reads.
  def action(:toggle, _params, component) do
    put_state(component, :open, !component.state.open)
  end

  def template do
    ~HOLO"""
    <main>
      <h1>Hologram: every action re-renders all 300 cards</h1>
      <p>
        Both buttons run a client-side action. <b>No-op</b> returns the page unchanged.
        <b>Toggle panel</b> flips one boolean that only the small panel reads.
        Hologram still evaluates every card template and diffs the whole tree.
        Issue: <a href="https://github.com/bartblast/hologram/issues/1381">bartblast/hologram#1381</a>.
      </p>
      <p class="buttons">
        <button type="button" id="noop" $click="noop">No-op action</button>
        <button type="button" id="toggle" $click="toggle">Toggle panel</button>
      </p>
      <p>Click a button. Each line below shows Hologram's own "page rendered in" time and how many card templates that render evaluated.</p>
      <pre id="timings"></pre>
      <Panel open={@open} />
      <div class="grid">
        {%for i <- @cards}
          <Card index={i} />
        {/for}
      </div>
    </main>
    """
  end
end
