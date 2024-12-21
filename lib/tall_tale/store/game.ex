defmodule TallTale.Store.Game do
  use TallTale.Store.Schema
  alias TallTale.Store.Screen

  schema "games" do
    field :name, :string

    has_many :screens, Screen
    timestamps()
  end

  def changeset(game, attrs) do
    game
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  defimpl Phoenix.Param do
    def to_param(%@for{name: name}), do: name
  end
end
