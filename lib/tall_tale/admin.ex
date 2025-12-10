defmodule TallTale.Admin do
  import Ecto.Query, only: [from: 2]
  alias TallTale.Repo
  alias TallTale.Store.Game
  alias TallTale.Store.Quality
  alias TallTale.Store.Screen

  def games do
    Repo.all(Game)
  end

  if Mix.env() == :prod do
    def published_games do
      Repo.all(from g in Game, where: g.published)
    end
  else
    def published_games, do: games()
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
        preload: [
          screens: ^from(s in Screen, order_by: [asc: :name]),
          qualities: ^from(q in Quality, order_by: [asc: :name])
        ]

    Repo.one(q)
  end

  if Mix.env() == :prod do
    def load_published_game(name, code)

    def load_published_game(name, nil) do
      q =
        from g in Game,
          where: g.name == ^name and g.published,
          preload: [screens: ^from(s in Screen, order_by: [asc: :name])]

      Repo.one(q)
    end

    def load_published_game(name, code) do
      q =
        from g in Game,
          left_join: a in assoc(g, :access_codes),
          where: g.name == ^name and (g.published or a.code == ^code),
          preload: [screens: ^from(s in Screen, order_by: [asc: :name])]

      Repo.one(q)
    end
  else
    def load_published_game(name, _code), do: load_game(name)
  end

  def reload_game(game) do
    load_game(game.name)
  end

  def create_screen(game, attrs) do
    Ecto.build_assoc(game, :screens)
    |> Screen.changeset(attrs)
    |> Repo.insert()
  end

  def create_quality(game, attrs) do
    Ecto.build_assoc(game, :qualities)
    |> Quality.changeset(attrs)
    |> Repo.insert()
  end

  def put_screen_blocks(screen, blocks) do
    screen
    |> Ecto.Changeset.change(blocks: blocks)
    |> Repo.update()
  end

  def remove_deleted_blocks(blocks) do
    blocks
    |> Enum.map(fn
      %{"blocks" => blocks} = block -> %{block | "blocks" => remove_deleted_blocks(blocks)}
      block -> block
    end)
    |> Enum.reject(fn
      %{"delete" => "true"} -> true
      _ -> false
    end)
  end
end
