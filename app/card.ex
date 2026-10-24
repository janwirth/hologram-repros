defmodule HologramSkeleton.Card do
  @moduledoc """
  Stateless card. Its only input is `index`, which never changes after the
  first render, so re-evaluating this template on an action is wasted work.
  """
  use Hologram.Component

  prop :index, :integer

  def template do
    ~HOLO"""
    <div class="card">
      <strong>Card {@index}</strong>
      {%if rem(@index, 3) == 0}<span class="tag">every third</span>{/if}
      <p>Stateless component, props unchanged on every action.</p>
    </div>
    """
  end
end
