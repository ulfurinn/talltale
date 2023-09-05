defmodule Talltale.Game.Deck do
  @moduledoc "A deck of cards for a particular location."
  use Talltale.Schema

  alias Talltale.Game.Card
  alias Talltale.Game.Tale

  schema "decks" do
    field :title, :string

    belongs_to :tale, Tale
    has_many :cards, Card
  end

  def draw(%__MODULE__{cards: cards}, n) do
    draw(cards, n)
  end

  def draw(cards, n) when is_list(cards) do
    draw(cards, n, [])
  end

  defp draw(_, 0, acc), do: acc
  defp draw([], _, acc), do: acc

  defp draw(cards, n, acc) do
    {cards, card} = draw(cards)
    draw(cards, n - 1, [card | acc])
  end

  defp draw(cards) do
    {cards, index} = build_ranges(cards)

    cards = Enum.reverse(cards)
    index = Enum.random(0..(index - 1))
    {cards, {_, card}} = take_when(cards, fn {range, _} -> index in range end)
    {cards, card}
  end

  defp build_ranges(cards) do
    cards
    |> Enum.reduce({[], 0}, fn card, {cards, index} ->
      card =
        case card do
          {_, card} -> card
          card -> card
        end

      range = index..(index + card.frequency - 1)
      {[{range, card} | cards], index + card.frequency}
    end)
  end

  defp take_when(list, predicate)
  defp take_when([], _), do: {[], nil}

  defp take_when([el | tail], predicate) do
    if predicate.(el) do
      {tail, el}
    else
      {tail, result} = take_when(tail, predicate)
      {[el | tail], result}
    end
  end
end
