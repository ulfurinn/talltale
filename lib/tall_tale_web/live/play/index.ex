defmodule TallTaleWeb.PlayLive.Index do
  use TallTaleWeb, :live_view

  def mount(_params, _session, socket) do
    socket
    |> assign(:games, TallTale.Admin.games())
    |> ok()
  end
end
