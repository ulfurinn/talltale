defmodule TallTale.Store.Quality do
  use TallTale.Store.Schema
  alias TallTale.Store.Game

  schema "qualities" do
    field :name, :string
    field :identifier, :string
    belongs_to :game, Game

    timestamps()
  end

  @doc false
  def changeset(quality, attrs) do
    quality
    |> cast(attrs, [:name, :identifier])
    |> validate_required([:identifier])
  end
end
