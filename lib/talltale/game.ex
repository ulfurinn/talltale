defmodule Talltale.Game do
  @moduledoc "Game state."
  alias Talltale.Expression
  alias Talltale.Game.Area
  alias Talltale.Game.Card
  alias Talltale.Game.Deck
  alias Talltale.Game.Location
  alias Talltale.Game.Outcome
  alias Talltale.Game.Storylet
  alias Talltale.Game.Tale

  require Logger

  defstruct [
    :tale,
    :deck,
    :hand,
    qualities: %{},
    storylet: nil,
    outcome: nil
  ]

  def new(tale) do
    %__MODULE__{
      tale: tale,
      qualities: tale.start
    }
    |> form_deck()
    |> draw()
  end

  def snapshot(game) do
    %{
      qualities: game.qualities,
      storylet: if(game.storylet, do: game.storylet.id, else: nil),
      deck: Enum.map(game.deck, fn card -> card.id end),
      hand:
        Enum.map(game.hand, fn
          nil -> nil
          card -> card.id
        end)
    }
  end

  def restore(game, snapshot) do
    qualities = snapshot["qualities"]

    storylet =
      if snapshot["storylet"] do
        game.tale.storylets[snapshot["storylet"]] |> filter_storylet_choices(qualities)
      else
        nil
      end

    deck = snapshot["deck"] |> Enum.map(&game.tale.cards[&1])

    hand =
      snapshot["hand"]
      |> Enum.map(fn
        nil -> nil
        id -> Card.gen_ref(game.tale.cards[id])
      end)
      |> Arrays.new()

    %__MODULE__{
      game
      | qualities: qualities,
        storylet: storylet,
        deck: deck,
        hand: hand
    }
  end

  def reshuffle(game) do
    game
    |> form_deck()
    |> draw()
  end

  def put_quality(game, id, value) do
    %__MODULE__{game | qualities: Map.put(game.qualities, id, String.to_integer(value))}
    |> check_card_conditions()
  end

  defp form_deck(
         game = %__MODULE__{
           tale: %Tale{areas: areas, locations: locations, decks: decks, cards: cards},
           qualities: qualities
         }
       ) do
    Logger.info("forming deck")
    area = areas[qualities["area"]]

    location =
      case area do
        nil -> nil
        %Area{} -> locations[qualities["location"]]
      end

    card_ids = deck_cards(area, decks) ++ deck_cards(location, decks)
    deck = Map.take(cards, Enum.uniq(card_ids)) |> Map.values()

    %__MODULE__{game | deck: deck}
  end

  defp deck_cards(nil, _), do: []
  defp deck_cards(%{deck_id: id}, decks), do: deck_cards(decks[id])

  defp deck_cards(nil), do: []
  defp deck_cards(%Deck{card_ids: ids}), do: ids

  def draw(game = %__MODULE__{deck: deck, qualities: qualities}) do
    hand =
      deck
      |> Enum.filter(&eval_condition(game, &1.condition))
      |> Deck.draw(qualities["hand_size"])
      |> Enum.map(&Card.gen_ref/1)
      |> Enum.into(IntoArray.new(Arrays.empty(size: qualities["hand_size"])))

    %__MODULE__{game | hand: hand}
  end

  def play_card(game, card = %Card{pass: %Outcome{effects: effects}}) do
    game
    |> apply_effect(effects)
    |> remove_card(card)
    |> check_card_conditions()
    |> maybe_update_deck(game)
    |> tap(&log_game_state/1)
  end

  defp remove_card(game = %__MODULE__{hand: hand}, card) do
    replacement =
      if card.sticky do
        Card.gen_ref(card)
      else
        nil
      end

    index = hand |> Enum.find_index(&(&1 && &1.id == card.id))
    hand = hand |> Arrays.replace(index, replacement)
    %__MODULE__{game | hand: hand}
  end

  defp check_card_conditions(game = %__MODULE__{hand: hand}) do
    hand
    |> Arrays.map(fn card ->
      if eval_condition(game, card && card.condition) do
        card
      else
        nil
      end
    end)
    |> then(&%__MODULE__{game | hand: &1})
  end

  def play_storylet_choice(game, choice_id) do
    initial_game = game
    choice = game.storylet.choices |> Enum.find(&(&1.id == choice_id))

    pass =
      choice.challenges
      |> Enum.all?(fn challenge ->
        prob = challenge_chance(game, challenge)
        :rand.uniform() < prob
      end)

    game =
      if pass do
        apply_outcome(game, choice.pass)
      else
        apply_outcome(game, choice.fail)
      end

    game
    |> check_card_conditions()
    |> maybe_update_deck(initial_game)
    |> tap(&log_game_state/1)
  end

  defp apply_outcome(game, outcome = %Outcome{effects: effects}) do
    game
    |> apply_effect(effects)
    |> clear_storylet()
    |> put_outcome(outcome)
  end

  def challenge_chance(game, challenge) do
    generator = Expression.eval(challenge.generator_expression, game.qualities)
    generator.(game.qualities[challenge.quality.variable] || 0)
  end

  def build_storyline(game, %Location{storylines: storylines}) do
    storylines
    |> Enum.filter(&eval_condition(game, &1.condition))
  end

  defp eval_condition(_, nil), do: true

  defp eval_condition(%__MODULE__{qualities: qualities}, expression) do
    eval_condition(qualities, expression)
  end

  defp eval_condition(qualities, expression) do
    Expression.eval_boolean(expression, qualities)
  end

  defp apply_effect(game, effects) when is_list(effects) do
    effects
    |> Enum.reduce(game, &apply_effect(&2, &1))
  end

  defp apply_effect(game = %__MODULE__{}, {:quality, expression}) do
    %__MODULE__{
      qualities: qualities
    } = game

    %__MODULE__{game | qualities: Expression.eval_assign(expression, qualities)}
  end

  defp apply_effect(game = %__MODULE__{}, {:location, location_id}) do
    %__MODULE__{
      qualities: qualities,
      tale: %Tale{locations: locations}
    } = game

    area_id = locations[qualities["location"]].area_id

    %__MODULE__{
      game
      | qualities: qualities |> Map.put("area", area_id) |> Map.put("location", location_id)
    }
  end

  defp apply_effect(
         game = %__MODULE__{tale: %Tale{storylets: storylets}},
         {:storylet, storylet_id}
       ) do
    storylet = storylets[storylet_id] |> filter_storylet_choices(game)

    %__MODULE__{game | storylet: storylet}
  end

  defp apply_effect(game = %__MODULE__{}, nil) do
    game
  end

  defp clear_storylet(game), do: %__MODULE__{game | storylet: nil}

  defp put_outcome(game, outcome), do: %__MODULE__{game | outcome: outcome}
  def clear_outcome(game), do: %__MODULE__{game | outcome: nil}

  defp filter_storylet_choices(storylet, game_or_qualities) do
    %Storylet{
      storylet
      | choices: Enum.filter(storylet.choices, &eval_condition(game_or_qualities, &1.condition))
    }
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

  defp empty_hand?(%__MODULE__{hand: hand}), do: Enum.all?(hand, &is_nil/1)

  defp changed_location?(
         %__MODULE__{qualities: updated_qualities},
         %__MODULE__{qualities: qualities}
       ) do
    updated_qualities["area"] != qualities["area"] ||
      updated_qualities["location"] != qualities["location"]
  end

  defp log_game_state(%__MODULE__{qualities: qualities, hand: hand}) do
    Logger.debug("qualities: #{inspect(qualities)}")
    Logger.debug("hand: #{inspect(Enum.map(hand, &(&1 && &1.title)))}")
  end
end
