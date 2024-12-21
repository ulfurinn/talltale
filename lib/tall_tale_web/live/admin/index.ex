defmodule TallTaleWeb.AdminLive.Index do
  use TallTaleWeb, :live_view

  def mount(_params, _session, socket) do
    socket
    |> ok()
  end
end
