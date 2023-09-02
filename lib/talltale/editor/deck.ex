defmodule Talltale.Editor.Deck do
  use Talltale.Schema

  alias Talltale.Editor.Card

  schema "decks" do
    has_many :cards, Card
  end
end
