defmodule HologramSkeleton.SlowBundles do
  @moduledoc """
  Delays every Hologram JS bundle (/hologram/*.js) by `delay_ms/0`, standing in
  for a large bundle on a slow connection. DELAY_MS overrides the default.
  """
  @behaviour Plug

  def delay_ms, do: String.to_integer(System.get_env("DELAY_MS", "4000"))

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%Plug.Conn{request_path: "/hologram/" <> rest} = conn, _opts) do
    if String.ends_with?(rest, ".js"), do: Process.sleep(delay_ms())
    conn
  end

  def call(conn, _opts), do: conn
end
