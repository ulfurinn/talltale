defmodule Talltale.Editor.Deck do
  @moduledoc "A deck of cards for a particular location."
  use Talltale.Schema

  alias Talltale.Editor.Card

  schema "decks" do
    has_many :cards, Card
  end
end
