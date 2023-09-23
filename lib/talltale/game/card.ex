defmodule Talltale.Game.Card do
  @moduledoc "An action."
  use Talltale.Schema

  alias Talltale.Game.Deck

  schema "cards" do
    field :title, :string
    field :frequency, :integer
    field :condition, :string
    field :sticky, :boolean
    field :effect, Talltale.JSONB

    belongs_to :deck, Deck

    field :ref, :any, virtual: true
  end

  def gen_ref(card) do
    %__MODULE__{card | ref: Uniq.UUID.uuid7()}
  end
end
