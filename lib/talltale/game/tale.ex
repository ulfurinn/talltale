defmodule Talltale.Game.Tale do
  @moduledoc "The entire story definition."
  use Talltale.Schema

  alias Talltale.Game.Area
  alias Talltale.Game.Deck
  alias Talltale.Game.Quality
  alias Talltale.Game.Storylet

  schema "tales" do
    field :slug, :string
    field :title, :string
    field :start, :map, default: %{}

    has_many :areas, Area
    # has_many :locations, through: [:areas, :locations]
    has_many :decks, Deck
    has_many :qualities, Quality
    has_many :storylets, Storylet
  end
end
