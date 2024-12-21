defmodule TallTale.Admin do
  alias TallTale.Repo
  alias TallTale.Store.Game

  def games do
    Repo.all(Game)
  end

  def create_game(attrs) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end
end
