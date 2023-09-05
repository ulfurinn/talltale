defmodule Talltale.Editor.Tale do
  @moduledoc "The entire story definition."
  use Talltale.Schema

  import Ecto.Changeset

  alias Talltale.Editor.Area
  alias Talltale.Editor.Deck
  alias Talltale.Editor.Quality

  schema "tales" do
    field :slug, :string
    field :title, :string
    field :start, Talltale.Dictionary, default: []

    has_many :areas, Area
    has_many :locations, through: [:areas, :locations]
    has_many :decks, Deck
    has_many :qualities, Quality
  end

  def changeset(tale, attrs) do
    tale
    |> cast(attrs, [:slug, :title, :start])
    |> validate_required([:slug, :title])
  end

  def get_area(%__MODULE__{areas: areas}, id: id) do
    areas |> Enum.find(&(&1.id == id))
  end

  def get_deck(%__MODULE__{decks: decks}, id: id) do
    decks |> Enum.find(&(&1.id == id))
  end
end
