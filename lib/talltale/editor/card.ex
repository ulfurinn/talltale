defmodule Talltale.Editor.Card do
  use Talltale.Schema

  alias Talltale.Editor.Deck
  alias Talltale.Editor.Tale

  schema "cards" do
    field :slug, :string
    field :title, :string
    field :frequency, :integer
    field :effect, Talltale.JSONB

    belongs_to :tale, Tale
    belongs_to :deck, Deck
  end
end
