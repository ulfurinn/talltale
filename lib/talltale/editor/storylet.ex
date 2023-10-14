defmodule Talltale.Editor.Storylet do
  use Talltale.Schema

  # import Ecto.Changeset

  alias Talltale.Editor.Card
  alias Talltale.Editor.Tale

  schema "storylets" do
    field :title, :string
    field :description, :string

    belongs_to :tale, Tale
    has_many :cards, Card
  end
end
