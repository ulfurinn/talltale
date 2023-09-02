defmodule Talltale.Game.Card do
  @moduledoc "An action."
  use Talltale.Schema

  alias Talltale.Game.Deck
  alias Talltale.Game.Tale

  schema "cards" do
    field :slug, :string
    field :title, :string
    field :frequency, :integer
    field :effect, Talltale.JSONB

    belongs_to :tale, Tale
    belongs_to :deck, Deck
  end
end
