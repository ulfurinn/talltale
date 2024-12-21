defmodule TallTale.Store.Screen do
  use TallTale.Store.Schema
  alias TallTale.Store.Game

  schema "screens" do
    field :name, :string
    belongs_to :game, Game

    timestamps()
  end

  @doc false
  def changeset(screen, attrs) do
    screen
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
