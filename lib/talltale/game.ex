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
      areas: Enum.into(tale.areas, %{}, fn area -> {area.slug, area} end),
      locations:
        Enum.into(tale.areas, %{}, fn area ->
          {area.slug,
           Enum.into(area.locations, %{}, fn location -> {location.slug, location} end)}
        end),
      qualities: tale.start |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), v} end)
    }
    |> form_deck()
    |> draw()
  end

  def form_deck(game = %__MODULE__{tale: tale, qualities: qualities}) do
    Logger.debug("forming deck")

    deck =
      Tale.form_deck(tale, qualities)
      |> Enum.filter(&(&1.condition == nil || eval_condition(&1.condition, qualities)))

    %__MODULE__{game | deck: deck}
  end

  def draw(game = %__MODULE__{deck: deck, qualities: qualities}) do
    cards = Deck.draw(deck, qualities.hand_size)
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
    |> Enum.filter(&(&1.condition == nil || eval_condition(&1.condition, qualities)))
  end

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
