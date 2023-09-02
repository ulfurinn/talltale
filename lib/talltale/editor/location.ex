defmodule Talltale.Editor.Location do
  @moduledoc "A game location."
  use Talltale.Schema

  import Ecto.Changeset

  alias Talltale.Editor.Area
  alias Talltale.Editor.Deck

  schema "locations" do
    field :slug, :string
    field :title, :string
    field :storyline, Talltale.JSONB, default: []

    belongs_to :area, Area
    belongs_to :deck, Deck
  end

  def changeset(tale, attrs) do
    tale
    |> cast(attrs, [:slug, :title, :storyline])
    |> validate_required([:slug, :title])
  end
end
