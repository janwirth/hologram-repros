defmodule HologramSkeleton.Panel do
  @moduledoc "Small panel whose only input is one boolean."
  use Hologram.Component

  prop :open, :boolean

  def template do
    ~HOLO"""
    <section class="panel">
      Panel is <strong>{%if @open}open{%else}closed{/if}</strong>
    </section>
    """
  end
end
