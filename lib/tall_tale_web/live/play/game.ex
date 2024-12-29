defmodule TallTaleWeb.PlayLive.Game do
  use TallTaleWeb, :live_view
  alias TallTale.Store.Game
  alias TallTale.Store.Screen
  alias TallTaleWeb.PlayLive.Block

  def mount(%{"game" => game_name}, _session, socket) do
    socket
    |> assign_game(game_name)
    |> assign_screen()
    |> assign_blocks()
    |> ok()
  end

  defp assign_game(socket, game_name) when is_binary(game_name) do
    assign_game(socket, TallTale.Admin.load_game(game_name))
  end

  defp assign_game(socket, %Game{} = game) do
    assign(socket, :game, game)
  end

  defp assign_screen(socket) do
    %{game: game} = socket.assigns
    %Game{screens: screens, starting_screen_id: starting_screen_id} = game
    screen = Enum.find(screens, &(&1.id == starting_screen_id))
    assign_screen(socket, screen)
  end

  defp assign_screen(socket, screen) do
    assign(socket, :screen, screen)
  end

  defp assign_blocks(socket) do
    %{screen: screen} = socket.assigns
    %Screen{blocks: blocks} = screen
    assign_blocks(socket, blocks)
  end

  defp assign_blocks(socket, blocks) do
    assign(socket, :blocks, blocks)
  end
end
