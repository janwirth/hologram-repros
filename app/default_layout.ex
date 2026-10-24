defmodule HologramSkeleton.DefaultLayout do
  use Hologram.Component

  def template do
    ~HOLO"""
    <!DOCTYPE html>
    <html>
      <head>
        <title>Hologram re-render demo</title>
        <link rel="stylesheet" href="/demo.css" />
        <script src="/demo.js"></script>
        <Hologram.UI.Runtime />
      </head>
      <body>
        <slot />
      </body>
    </html>
    """
  end
end
