defmodule TallTaleWeb.PlayLive.Game do
  use TallTaleWeb, :live_view
  alias TallTale.GameState
  alias TallTaleWeb.PlayLive.Block

  def mount(%{"game" => game_name}, _session, socket) do
    socket
    |> assign_game_state(game_name)
    |> assign_shortcuts()
    |> ok()
  end

  def handle_event("execute-action", %{"block-id" => block_id}, socket) do
    %{game_state: game_state} = socket.assigns

    socket
    |> assign(:game_state, GameState.execute_action(game_state, block_id))
    |> assign_shortcuts()
    # |> push_event("animate", %{
    #   id: "block-" <> block_id,
    #   ref: Uniq.UUID.uuid7(),
    #   transition: %{type: "fade-out", after: "hide"}
    # })
    |> noreply()
  end

  def handle_event("transition-ended", %{"ref" => ref}, socket) do
    socket |> noreply()
  end

  defp assign_game_state(socket, game_name) when is_binary(game_name) do
    assign_game_state(socket, GameState.new(TallTale.Admin.load_game(game_name)))
  end

  defp assign_game_state(socket, game_state) do
    assign(socket, :game_state, game_state)
  end

  defp assign_shortcuts(socket) do
    %{game_state: game_state} = socket.assigns

    socket
    |> assign(:game, game_state.game)
    |> assign(:screen, game_state.screen)
    |> assign(:blocks, game_state.screen.blocks)
  end
end
