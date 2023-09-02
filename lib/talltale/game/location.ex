defmodule Talltale.Game.Location do
  use Talltale.Schema

  alias Talltale.Game.Area
  alias Talltale.Game.Deck

  schema "locations" do
    field :slug, :string
    field :title, :string
    field :storyline, Talltale.JSONB

    belongs_to :area, Area
    belongs_to :deck, Deck
  end
end
