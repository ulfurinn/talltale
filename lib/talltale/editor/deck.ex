defmodule Talltale.Editor.Deck do
  @moduledoc "A deck of cards for a particular location."
  use Talltale.Schema

  import Ecto.Changeset

  alias Talltale.Editor.Card
  alias Talltale.Editor.Tale

  schema "decks" do
    field :title, :string

    belongs_to :tale, Tale
    has_many :cards, Card
  end

  def changeset(area, attrs) do
    area
    |> cast(attrs, [:title])
    |> validate_required([:title])
  end

  def get_card(%__MODULE__{cards: cards}, id: id) do
    cards |> Enum.find(&(&1.id == id))
  end
end
