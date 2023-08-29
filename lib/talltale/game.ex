defmodule Talltale.Game do
  alias Talltale.Deck
  alias Talltale.Tale

  defstruct [
    :tale,
    :qualities,
    :deck,
    :cards
  ]

  def new(tale) do
    %__MODULE__{tale: tale, qualities: tale.start}
    |> shuffle()
    |> draw()
  end

  def shuffle(game = %__MODULE__{tale: tale, qualities: qualities}) do
    deck = Tale.shuffle(tale, qualities)
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

  defp remove_card(game = %__MODULE__{deck: deck}, id) do
    deck = deck |> Enum.reject(&(&1.id == id))
    %__MODULE__{game | deck: deck}
  end

  defp apply_effect(game, effect) do
    effect
    |> Enum.reduce(game, fn {key, value}, game ->
      apply_effect(game, key, value)
    end)
  end

  defp apply_effect(game = %__MODULE__{qualities: qualities}, key, value)
       when is_binary(value) or is_number(value) do
    %__MODULE__{game | qualities: Map.put(qualities, key, value)}
  end

  defp maybe_update_deck(updated_game, game) do
    if changed_location?(updated_game, game) do
      updated_game
      |> shuffle()
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
