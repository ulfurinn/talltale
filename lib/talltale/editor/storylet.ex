defmodule Talltale.Editor.Storylet do
  use Talltale.Schema

  import Ecto.Changeset

  alias Talltale.Editor.Card
  alias Talltale.Editor.Tale

  schema "storylets" do
    field :title, :string
    field :description, :string

    belongs_to :tale, Tale
    has_many :cards, Card
  end

  def changeset(storylet, attrs) do
    storylet
    |> cast(attrs, [:title, :description])
    |> validate_required([:title, :description])
  end

  def get_card(%__MODULE__{cards: cards}, id: id) do
    cards |> Enum.find(&(&1.id == id))
  end

  def build_card(deck), do: deck |> Ecto.build_assoc(:cards)
end
