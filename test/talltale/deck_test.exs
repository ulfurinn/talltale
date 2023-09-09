defmodule Talltale.DeckTest do
  use ExUnit.Case

  alias Talltale.Game.Card
  alias Talltale.Game.Deck

  test "gets some cards" do
    cards = [
      %Card{frequency: 1, id: 1},
      %Card{frequency: 1, id: 2},
      %Card{frequency: 1, id: 3},
      %Card{frequency: 1, id: 4},
      %Card{frequency: 1, id: 5}
    ]

    draw = Deck.draw(cards, 3)
    assert length(draw) == 3
  end

  test "gets as many cards as there are" do
    cards = [
      %Card{frequency: 1, id: 1},
      %Card{frequency: 1, id: 2}
    ]

    draw = Deck.draw(cards, 3)
    assert length(draw) == 2
  end

  test "(almost) always gets an extremely likely card" do
    1..100_000
    |> Enum.each(fn _ ->
      cards = [
        %Card{frequency: 10_000, id: 1},
        %Card{frequency: 1, id: 2},
        %Card{frequency: 1, id: 3},
        %Card{frequency: 1, id: 4},
        %Card{frequency: 1, id: 5}
      ]

      draw = Deck.draw(cards, 3)
      assert Enum.find(draw, &(&1.id == 1))
    end)
  end
end
