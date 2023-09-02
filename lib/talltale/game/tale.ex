defmodule Talltale.Game.Tale do
  @moduledoc "The entire story definition."
  use Talltale.Schema

  alias Talltale.Game.Area
  alias Talltale.Game.Card
  alias Talltale.Game.Deck
  alias Talltale.Game.Quality

  schema "tales" do
    field :slug, :string
    field :title, :string
    field :start, :map, default: %{}

    has_many :areas, Area
    has_many :locations, through: [:areas, :locations]
    has_many :cards, Card
    has_many :qualities, Quality
  end

  def form_deck(tale, qualities) do
    area = tale.areas |> Enum.find(&(&1.slug == qualities.area))

    location =
      case area do
        nil -> nil
        area -> area.locations |> Enum.find(&(&1.slug == qualities.location))
      end

    deck_cards(area) ++ deck_cards(location)
  end

  defp deck_cards(%{deck: deck}), do: deck_cards(deck)
  defp deck_cards(nil), do: []
  defp deck_cards(%Deck{cards: cards}), do: cards
end
