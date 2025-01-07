defmodule TallTaleWeb.PlayLive.Game do
  alias TallTale.Commands.SetScreen
  alias TallTale.Commands.Transition
  use TallTaleWeb, :live_view
  alias TallTale.GameState
  alias TallTale.Store.Game
  alias TallTaleWeb.PlayLive.Block

  def mount(%{"game" => game_name}, _session, socket) do
    case TallTale.Admin.load_published_game(game_name) do
      game = %Game{} ->
        socket
        |> assign_game_state(game)
        |> assign_shortcuts()
        |> ok()

      nil ->
        socket
        |> push_navigate(to: ~p"/")
        |> ok()
    end
  end

  def handle_event("execute-action", %{"block-id" => block_id}, socket) do
    %{game_state: game_state} = socket.assigns

    socket
    |> assign_game_state(GameState.execute_action(game_state, block_id))
    |> execute_commands()
    |> assign_shortcuts()
    |> noreply()
  end

  def handle_event("go-to-screen", %{"screen-id" => screen_id}, socket) do
    %{game_state: game_state} = socket.assigns

    socket
    |> assign_game_state(GameState.go_to_screen(game_state, screen_id))
    |> execute_commands()
    |> assign_shortcuts()
    |> noreply()
  end

  def handle_event("transition-ended", %{"id" => id}, socket) do
    %{game_state: game_state} = socket.assigns

    socket
    |> assign_game_state(GameState.promote_delayed_commands(game_state, id))
    |> execute_commands()
    |> assign_shortcuts()
    |> noreply()
  end

  defp assign_game_state(socket, game = %Game{}) do
    assign_game_state(socket, GameState.new(game))
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

  defp execute_commands(socket) do
    %{game_state: game_state} = socket.assigns
    {socket, game_state} = execute_commands(socket, game_state)
    assign_game_state(socket, game_state)
  end

  defp execute_commands(socket, game_state = %GameState{commands: []}), do: {socket, game_state}

  defp execute_commands(socket, game_state = %GameState{commands: [command | rest]}) do
    {socket, game_state} = execute_command(socket, game_state, command)
    execute_commands(socket, %GameState{game_state | commands: rest})
  end

  defp execute_command(socket, game_state, command = %Transition{}) do
    socket
    |> push_event("animate", %{
      target: transition_target_id(game_state, command.target),
      id: command.id,
      transition: %{
        type: command.type,
        clear: command.clear,
        after: command.after,
        duration: command.duration
      }
    })
    |> with_game_state(game_state)
  end

  defp execute_command(socket, game_state, command = %SetScreen{}) do
    socket |> with_game_state(GameState.set_screen(game_state, command.screen_id))
  end

  defp transition_target_id(game_state, :screen), do: "screen-#{game_state.screen.id}"

  defp with_game_state(socket, game_state), do: {socket, game_state}
end
