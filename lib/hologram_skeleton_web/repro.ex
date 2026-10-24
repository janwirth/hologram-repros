defmodule HologramSkeletonWeb.Repro do
  @moduledoc """
  Dev-only routes that drive the repro.

    * `GET /repro/trigger` - puts a dangling symlink in `priv/static/assets`
      (a chunk file listed by `File.ls!/1` that is neither regular nor a dir),
      bumps `@revision` in `app/home_page.ex` so live reload runs a pass, and
      removes the symlink again after 20 s.
    * `GET /repro/reset` - removes the symlink and bumps `@revision`: a clean
      pass that brings the page back.

  Both redirect to `/` after 10 s, once the pass is done (there is no API to
  wait for a pass, see part 2 of the issue).
  """
  import Plug.Conn

  @page "app/home_page.ex"
  @vanished "priv/static/assets/chunk-VANISHED.js"

  def init(opts), do: opts

  def call(%{path_info: ["repro", "trigger"]} = conn, _opts) do
    File.mkdir_p!(Path.dirname(@vanished))
    File.rm(@vanished)
    File.ln_s!("chunk-VANISHED.js.removed-by-esbuild", @vanished)
    bump_revision()

    # Long past the pass, so the next app boot does not scan it.
    Task.start(fn ->
      Process.sleep(20_000)
      File.rm(@vanished)
    end)

    waiting(conn, "Triggered: vanished chunk file added, page edited.")
  end

  def call(%{path_info: ["repro", "reset"]} = conn, _opts) do
    File.rm(@vanished)
    bump_revision()
    waiting(conn, "Reset: vanished chunk file removed, page edited.")
  end

  def call(conn, _opts), do: conn

  defp bump_revision do
    source = File.read!(@page)
    [_, n] = Regex.run(~r/@revision (\d+)/, source)
    File.write!(@page, String.replace(source, "@revision #{n}", "@revision #{String.to_integer(n) + 1}"))
  end

  defp waiting(conn, message) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, """
    <meta http-equiv="refresh" content="10;url=/">
    <p style="font-family: sans-serif">#{message} Live reload runs a pass; back to the page in 10 s.</p>
    """)
    |> halt()
  end
end
