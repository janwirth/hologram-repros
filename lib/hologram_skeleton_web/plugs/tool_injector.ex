defmodule HologramSkeletonWeb.Plugs.ToolInjector do
  @moduledoc """
  Stands in for a dev tool such as Tidewave or Phoenix.LiveReloader: on every
  HTML response it appends a config `<meta>` and an inline `<script>` to the
  end of `<head>`, and a badge `<div>` to the end of `<body>`.

  The script records whether those nodes exist when it runs, then checks again
  1.5 s later, after Hologram has booted, and reports the result in a fixed
  banner and in the console.
  """
  @behaviour Plug

  import Plug.Conn

  @head_tail """
  <meta name="x-tool:config" content='{"tool":"x-tool"}'>
  <script id="x-tool-script">
  (function () {
    var check = function () {
      return {
        meta: !!document.querySelector('meta[name="x-tool:config"]'),
        script: !!document.getElementById("x-tool-script"),
        badge: !!document.getElementById("x-tool-badge"),
        liveReloadIframe: !!document.querySelector('iframe[src*="live_reload"]')
      };
    };
    var show = function (label, s) {
      return label + ": meta " + (s.meta ? "present" : "MISSING") +
        ", head script " + (s.script ? "present" : "MISSING") +
        ", body badge " + (s.badge ? "present" : "MISSING") +
        ", LiveReloader iframe " + (s.liveReloadIframe ? "present" : "MISSING");
    };
    var before;
    document.addEventListener("DOMContentLoaded", function () {
      before = check();
      console.log("[x-tool] " + show("before Hologram boot", before));
    });
    window.addEventListener("load", function () {
      setTimeout(function () {
        var after = check();
        var ok = after.meta && after.script && after.badge && after.liveReloadIframe;
        var msg = show("1.5 s after load", after);
        (ok ? console.log : console.error)("[x-tool] " + msg);
        var banner = document.createElement("div");
        banner.id = "x-tool-banner";
        banner.setAttribute("data-ok", ok ? "yes" : "no");
        banner.style.cssText = "position:fixed;top:0;left:0;right:0;padding:0.75rem 1rem;" +
          "font:15px/1.4 monospace;color:#fff;z-index:99999;background:" + (ok ? "#1a7f37" : "#cf222e");
        banner.textContent = (ok ? "OK - nodes kept. " : "BUG - Hologram removed appended nodes. ") +
          msg + " (before boot: meta " + (before && before.meta ? "present" : "MISSING") + ")";
        document.body.appendChild(banner);
      }, 1500);
    });
  })();
  </script>
  """

  @body_tail """
  <div id="x-tool-badge" style="position:fixed;bottom:1rem;right:1rem;padding:0.5rem 0.75rem;background:#0969da;color:#fff;font:14px sans-serif;border-radius:6px;">
    x-tool badge (appended to &lt;body&gt; by a plug)
  </div>
  """

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    register_before_send(conn, fn conn ->
      html? =
        conn
        |> get_resp_header("content-type")
        |> Enum.any?(&String.starts_with?(&1, "text/html"))

      if html? and conn.resp_body != nil do
        body =
          conn.resp_body
          |> IO.iodata_to_binary()
          |> String.replace("</head>", @head_tail <> "</head>", global: false)
          |> String.replace("</body>", @body_tail <> "</body>", global: false)

        %{conn | resp_body: body}
      else
        conn
      end
    end)
  end
end
