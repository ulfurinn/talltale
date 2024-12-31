defmodule TallTale.Store.Game do
  use TallTale.Store.Schema
  alias TallTale.Store.Screen

  schema "games" do
    field :name, :string
    field :starting_screen_id, Uniq.UUID

    has_many :screens, Screen
    timestamps()
  end

  def changeset(game, attrs \\ %{}) do
    game
    |> cast(attrs, [:name, :starting_screen_id])
    |> validate_required([:name])
  end

  def starting_screen(game) do
    find_screen(game, game.starting_screen_id)
  end

  def find_screen(game, screen_id) do
    Enum.find(game.screens, &(&1.id == screen_id))
  end

  defimpl Phoenix.Param do
    def to_param(%@for{name: name}), do: name
  end
end
