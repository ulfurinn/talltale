defmodule TallTaleWeb.AdminLive.Index do
  use TallTaleWeb, :live_view

  def mount(_params, _session, socket) do
    socket
    |> assign(:games, TallTale.Admin.games())
    |> ok()
  end

  def handle_event("create-game", %{"name" => name}, socket) do
    case TallTale.Admin.create_game(%{name: name}) do
      {:ok, game} ->
        socket
        |> push_navigate(to: ~p"/admin/#{game}")
        |> noreply()

      {:error, _reason} ->
        {:noreply, socket}
    end
  end
end
