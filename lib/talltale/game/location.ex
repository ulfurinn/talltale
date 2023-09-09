defmodule Talltale.Game.Location do
  @moduledoc "A game location."
  use Talltale.Schema

  alias Talltale.Game.Area
  alias Talltale.Game.Deck
  alias Talltale.Game.Storyline

  schema "locations" do
    field :slug, :string
    field :title, :string
    embeds_many :storyline, Storyline

    belongs_to :area, Area
    belongs_to :deck, Deck
  end
end
