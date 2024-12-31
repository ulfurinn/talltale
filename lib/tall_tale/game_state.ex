defmodule TallTale.GameState do
  alias __MODULE__
  alias TallTale.Store.Game
  alias TallTale.Store.Screen

  defstruct [
    :game,
    :screen,
    qualities: %{}
  ]

  def new(game) do
    %GameState{
      game: game,
      screen: Game.starting_screen(game)
    }
  end

  def execute_action(state, block_id) when is_binary(block_id) do
    %GameState{screen: screen} = state
    execute_action(state, Screen.find_block(screen, block_id))
  end

  def execute_action(state, %{"button" => %{"next_screen" => screen_id}}) when screen_id != "" do
    %GameState{game: game} = state

    %GameState{
      game: game,
      screen: Game.find_screen(game, screen_id)
    }
  end
end
