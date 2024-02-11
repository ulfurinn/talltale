defmodule Talltale.Game.Deck do
  @moduledoc "A deck of cards for a particular location."

  defstruct [:id, :title, :card_ids]

  def draw(cards, n) when is_list(cards) do
    max_endpoint = Enum.reduce(cards, 0, &(&1.frequency + &2))
    draw(cards, min(length(cards), n), max_endpoint, [])
  end

  defp draw(cards, n, max_endpoint, acc)
  defp draw(_, 0, _, acc), do: acc

  defp draw(cards, n, max_endpoint, acc) do
    point = Enum.random(0..(max_endpoint - 1))

    {cards, card} = take_at_point(cards, 0, point)
    draw(cards, n - 1, max_endpoint - card.frequency, [card | acc])
  end

  defp take_at_point([card | tail], acc, point) do
    card_point = acc + card.frequency

    if point >= acc && point < card_point do
      {tail, card}
    else
      {tail, drawn_card} = take_at_point(tail, card_point, point)
      {[card | tail], drawn_card}
    end
  end
end
