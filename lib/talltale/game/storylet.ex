defmodule Talltale.Game.Storylet do
  use Talltale.Schema

  alias Talltale.Game.Card
  alias Talltale.Game.Tale

  schema "storylets" do
    field :title, :string
    field :description, :string

    belongs_to :tale, Tale
    has_many :cards, Card
  end
end
