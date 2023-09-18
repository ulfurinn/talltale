defmodule Talltale.Game.Card do
  @moduledoc "An action."
  use Talltale.Schema

  alias Talltale.Game.Deck

  schema "cards" do
    field :title, :string
    field :frequency, :integer
    field :condition, :string
    field :effect, Talltale.JSONB

    belongs_to :deck, Deck
  end
end
