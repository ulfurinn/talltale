defmodule TallTale.Store.Game do
  use TallTale.Store.Schema
  alias TallTale.Store.AccessCode
  alias TallTale.Store.Quality
  alias TallTale.Store.Screen

  schema "games" do
    field :name, :string
    field :starting_screen_id, Uniq.UUID
    field :published, :boolean, default: false

    has_many :screens, Screen
    has_many :qualities, Quality

    has_many :access_codes, AccessCode
    timestamps()
  end

  def changeset(game, attrs \\ %{}) do
    game
    |> cast(attrs, [:name, :starting_screen_id, :published])
    |> validate_required([:name])
  end

  def starting_screen(game) do
    find_screen(game, game.starting_screen_id)
  end

  def find_screen(game, screen_id) do
    Enum.find(game.screens, &(&1.id == screen_id))
  end

  def find_screen_by_name(game, name) do
    Enum.find(game.screens, &(&1.name == name))
  end

  defimpl Phoenix.Param do
    def to_param(%@for{name: name}), do: name
  end
end
