defmodule TalltaleWeb.GameLive do
  use TalltaleWeb, [:live_view, mode: :game]

  alias Talltale.Game
  alias Talltale.Repo

  embed_templates "*"

  def mount(params, _session, socket) do
    game = Game.new(Repo.load_tale(params["tale"]))

    socket
    |> assign(:theme, "game")
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
end
