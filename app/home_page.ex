defmodule HologramSkeleton.HomePage do
  @moduledoc """
  Reproduction: Hologram's first client-side render removes nodes that other
  tools append to the end of `<head>` and `<body>`.

  `HologramSkeletonWeb.Plugs.ToolInjector` appends a `<meta>` and a `<script>`
  to `<head>` and a badge `<div>` to `<body>` of every HTML response, the way
  Tidewave does; Phoenix.LiveReloader appends its `<iframe>` to `<body>`. The
  injected script reports in a banner whether those nodes survive the boot.
  """
  use Hologram.Page

  route "/"

  layout HologramSkeleton.DefaultLayout

  def init(_params, component, _server) do
    put_state(component, :count, 0)
  end

  def action(:increment, _params, component) do
    put_state(component, :count, component.state.count + 1)
  end

  def template do
    ~HOLO"""
    <main style="font-family: sans-serif; max-width: 40rem; margin: 5rem auto; line-height: 1.5;">
      <h1>Hologram: appended &lt;head&gt; / &lt;body&gt; nodes</h1>
      <p>
        A plug appends <code>&lt;meta name="x-tool:config"&gt;</code> and a
        <code>&lt;script&gt;</code> to the end of <code>&lt;head&gt;</code>, and a blue badge
        to the end of <code>&lt;body&gt;</code>, like Tidewave does. Phoenix LiveReloader
        appends its <code>&lt;iframe&gt;</code> to <code>&lt;body&gt;</code>.
      </p>
      <p>
        1.5 s after load the injected script checks whether those nodes still exist and
        shows the result in a banner at the top: green if they survived Hologram's
        boot, red if Hologram removed them. The blue badge in the corner disappears too.
      </p>
      <p id="count" style="font-size: 3rem; margin: 1rem 0;">{@count}</p>
      <p>
        <button type="button" $click="increment">+1</button>
      </p>
      <p style="color: #666; font-size: 0.9rem;">
        Issue: <a href="https://github.com/bartblast/hologram/issues/1380">bartblast/hologram#1380</a>
        · the plug is <code>lib/hologram_skeleton_web/plugs/tool_injector.ex</code>.
      </p>
    </main>
    """
  end
end
