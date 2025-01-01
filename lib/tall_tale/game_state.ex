defmodule TallTale.GameState do
  alias __MODULE__
  alias TallTale.Store.Game
  alias TallTale.Store.Screen
  alias TallTale.Commands.SetScreen
  alias TallTale.Commands.Transition

  defstruct [
    :game,
    :screen,
    qualities: %{},
    commands: [],
    delayed_commands: %{}
  ]

  def new(game) do
    %GameState{
      game: game,
      screen: Game.starting_screen(game)
    }
  end

  def set_screen(state, id) do
    %GameState{game: game} = state
    %GameState{state | screen: Game.find_screen(game, id)}
  end

  def execute_action(state, block_id) when is_binary(block_id) do
    %GameState{screen: screen} = state
    execute_action(state, Screen.find_block(screen, block_id))
  end

  def execute_action(state, %{"button" => %{"next_screen" => screen_id}}) when screen_id != "" do
    commands = [
      fade_out = Transition.fade_out(:screen)
    ]

    swap = [
      SetScreen.new(screen_id),
      Transition.fade_in(:screen)
    ]

    state
    |> with_commands(commands)
    |> with_delayed_commands(fade_out.id, swap)
  end

  def promote_delayed_commands(state, id) do
    state
    |> with_commands(state.delayed_commands[id] || [])
    |> with_delayed_commands(id, nil)
  end

  defp with_commands(state, commands) do
    %GameState{state | commands: commands}
  end

  defp with_delayed_commands(state, id, nil) do
    %GameState{state | delayed_commands: Map.delete(state.delayed_commands, id)}
  end

  defp with_delayed_commands(state, id, commands) do
    %GameState{state | delayed_commands: Map.put(state.delayed_commands, id, commands)}
  end
end
