defmodule Talltale.Game do
  @moduledoc "Game state."
  alias Talltale.Expression
  alias Talltale.Game.Card
  alias Talltale.Game.Deck

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
    Logger.info("forming deck")
    area = tale.areas |> Enum.find(&(&1.id == qualities.area))

    location =
      case area do
        nil -> nil
        area -> area.locations |> Enum.find(&(&1.id == qualities.location))
      end

    deck = deck_cards(area) ++ deck_cards(location)

    %__MODULE__{game | deck: deck}
  end

  defp deck_cards(%{deck: deck}), do: deck_cards(deck)
  defp deck_cards(nil), do: []
  defp deck_cards(%Deck{cards: cards}), do: cards

  def draw(game = %__MODULE__{deck: deck, qualities: qualities}) do
    cards =
      deck
      |> Enum.filter(&eval_condition(game, &1.condition))
      |> Deck.draw(qualities.hand_size)
      |> Enum.map(&Card.gen_ref/1)
      |> Enum.into(IntoArray.new(Arrays.empty(size: qualities.hand_size)))

    %__MODULE__{game | cards: cards}
  end

  def play_card(game, card) do
    game
    |> apply_effect(card.effect)
    |> remove_card(card)
    |> check_card_conditions()
    |> maybe_update_deck(game)
    |> tap(&log_game_state/1)
  end

  defp remove_card(game = %__MODULE__{cards: cards}, card) do
    replacement =
      if card.sticky do
        Card.gen_ref(card)
      else
        nil
      end

    index = cards |> Enum.find_index(&(&1 && &1.id == card.id))
    cards = cards |> Arrays.replace(index, replacement)
    %__MODULE__{game | cards: cards}
  end

  defp check_card_conditions(game = %__MODULE__{cards: cards}) do
    cards
    |> Arrays.map(fn card ->
      if eval_condition(game, card && card.condition) do
        card
      else
        nil
      end
    end)
    |> then(&%__MODULE__{game | cards: &1})
  end

  def build_storyline(game, location) do
    location.storyline
    |> Enum.filter(&eval_condition(game, &1.condition))
  end

  defp eval_condition(_, nil), do: true

  defp eval_condition(%__MODULE__{qualities: qualities}, expression) do
    Expression.eval_boolean(expression, qualities)
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

  defp apply_effect(game = %__MODULE__{qualities: qualities}, %{
         "set_location" => %{"area_id" => area_id, "location_id" => location_id}
       }) do
    %__MODULE__{game | qualities: %{qualities | area: area_id, location: location_id}}
  end

  defp apply_effect(game = %__MODULE__{}, nil) do
    game
  end

  defp maybe_update_deck(updated_game, game) do
    if changed_location?(updated_game, game) || empty_hand?(updated_game) do
      updated_game
      |> form_deck()
      |> draw()
    else
      updated_game
    end
  end

  defp empty_hand?(%__MODULE__{cards: cards}), do: Enum.all?(cards, &is_nil/1)

  defp changed_location?(
         %__MODULE__{qualities: updated_qualities},
         %__MODULE__{qualities: qualities}
       ) do
    updated_qualities.area != qualities.area || updated_qualities.location != qualities.location
  end

  defp log_game_state(game) do
    Logger.debug("qualities: #{inspect(game.qualities)}")
    Logger.debug("hand: #{inspect(Enum.map(game.cards, &(&1 && &1.title)))}")
  end
end
