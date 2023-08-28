defmodule TalltaleWeb.GameLive do
  use TalltaleWeb, :live_view

  alias Talltale.Game
  alias Talltale.Tale

  embed_templates "game/*"

  def mount(_params, _session, socket) do
    game = Game.new(Tale.talltale())

    socket
    |> put_game(game)
    |> ok()
  end

  def handle_event("action", %{"position" => position}, socket = %{assigns: %{game: game}}) do
    position = String.to_integer(position)
    card = game.cards |> Enum.at(position)
    game = Game.play_card(game, card)

    socket
    |> put_game(game)
    |> noreply()
  end

  defp put_game(socket, game) do
    socket
    |> assign(:game, game)
  end

  defp ok(socket) do
    {:ok, socket}
  end

  defp noreply(socket) do
    {:noreply, socket}
  end
end
