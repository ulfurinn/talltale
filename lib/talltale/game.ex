defmodule Talltale.Game do
  @moduledoc "Game state."
  alias Talltale.Expression
  alias Talltale.Game.Deck
  alias Talltale.Game.Tale

  require Logger

  defstruct [
    :tale,
    :areas,
    :locations,
    :qualities,
    :deck,
    :cards
  ]

  def new(tale) do
    %__MODULE__{
      tale: tale,
      areas: Enum.into(tale.areas, %{}, fn area -> {area.id, area} end),
      locations:
        Enum.into(tale.areas, %{}, fn area ->
          {area.id, Enum.into(area.locations, %{}, fn location -> {location.id, location} end)}
        end),
      qualities: tale.start |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)
    }
    |> form_deck()
    |> draw()
  end

  defp form_deck(game = %__MODULE__{tale: tale, qualities: qualities}) do
    deck =
      form_deck(tale, qualities)

    %__MODULE__{game | deck: deck}
  end

  defp form_deck(%Tale{areas: areas}, qualities) do
    area = areas |> Enum.find(&(&1.id == qualities.area))

    location =
      case area do
        nil -> nil
        area -> area.locations |> Enum.find(&(&1.id == qualities.location))
      end

    deck_cards(area) ++ deck_cards(location)
  end

  defp deck_cards(%{deck: deck}), do: deck_cards(deck)
  defp deck_cards(nil), do: []
  defp deck_cards(%Deck{cards: cards}), do: cards

  def draw(game = %__MODULE__{deck: deck, qualities: qualities}) do
    cards =
      deck
      |> Enum.filter(&eval_condition(&1.condition, qualities))
      |> Deck.draw(qualities.hand_size)

    %__MODULE__{game | cards: cards}
  end

  def play_card(game, card) do
    game
    |> remove_card(card.id)
    |> apply_effect(card.effect)
    |> maybe_update_deck(game)
  end

  defp remove_card(game = %__MODULE__{cards: cards}, id) do
    Logger.debug("removing card #{id}")
    cards = cards |> Enum.reject(&(&1.id == id))
    %__MODULE__{game | cards: cards}
  end

  def build_storyline(location, qualities) do
    location.storyline
    |> Enum.filter(&eval_condition(&1.condition, qualities))
  end

  defp eval_condition(nil, _), do: true

  defp eval_condition(expression, qualities) do
    Expression.eval(expression, qualities) == true
  end

  defp apply_effect(game, effects) when is_list(effects) do
    effects
    |> Enum.reduce(game, &apply_effect(&2, &1))
  end

  defp apply_effect(game = %__MODULE__{qualities: qualities}, %{
         "set_quality" => %{"expression" => expression}
       }) do
    %__MODULE__{game | qualities: Expression.eval_assign(expression, qualities)}
  end

  defp apply_effect(game = %__MODULE__{}, nil) do
    game
  end

  defp maybe_update_deck(updated_game, game) do
    if changed_location?(updated_game, game) || Enum.empty?(updated_game.cards) do
      updated_game
      |> form_deck()
      |> draw()
    else
      updated_game
    end
  end

  defp changed_location?(
         %__MODULE__{qualities: updated_qualities},
         %__MODULE__{qualities: qualities}
       ) do
    updated_qualities.area != qualities.area || updated_qualities.location != qualities.location
  end
end
