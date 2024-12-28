defmodule TallTale.Admin do
  import Ecto.Query, only: [from: 2]
  alias TallTale.Repo
  alias TallTale.Store.Game
  alias TallTale.Store.Screen

  def games do
    Repo.all(Game)
  end

  def create_game(attrs) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end

  def update_game(game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  def load_game(name) do
    q =
      from g in Game,
        where: g.name == ^name,
        preload: [screens: ^from(s in Screen, order_by: [asc: :name])]

    Repo.one(q)
  end

  def reload_game(game) do
    load_game(game.name)
  end

  def create_screen(game, attrs) do
    Ecto.build_assoc(game, :screens)
    |> Screen.changeset(attrs)
    |> Repo.insert()
  end

  def put_screen_blocks(screen, blocks) do
    screen
    |> Ecto.Changeset.change(blocks: blocks)
    |> Repo.update()
  end
end
