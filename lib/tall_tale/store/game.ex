defmodule TallTale.Store.Game do
  use TallTale.Store.Schema

  schema "games" do
    field :name, :string
    timestamps()
  end

  def changeset(game, attrs) do
    game
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
