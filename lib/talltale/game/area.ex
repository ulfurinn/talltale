defmodule Talltale.Game.Area do
  use Talltale.Schema

  alias Talltale.Game.Deck
  alias Talltale.Game.Location
  alias Talltale.Game.Tale

  schema "areas" do
    field :slug, :string
    field :title, :string

    belongs_to :tale, Tale
    has_many :locations, Location
    belongs_to :deck, Deck
  end
end
