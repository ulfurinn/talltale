defmodule TalltaleWeb.Game do
  @moduledoc false
  use TalltaleWeb, [:live_view, mode: :game]

  import TalltaleWeb.GameLive.HTML

  alias Talltale.Game
  alias Talltale.Game.Card
  # alias Talltale.Repo
  alias Talltale.Vault

  embed_templates "*"

  def mount(_params, _session, socket) do
    if connected?(socket) do
      tale = Vault.load("/Users/ulfurinn/Library/CloudStorage/Dropbox/obsidian/endless-town")
      game = Game.new(tale)

      socket
      |> assign(:theme, "game")
      |> assign(:loaded, true)
      |> put_game(game)
      |> assign_defaults()
      |> put_private(:on_animation_end, %{})
      |> ok()
    else
      socket
      |> assign(:theme, "game")
      |> assign(:loaded, false)
      |> ok()
    end
  end

  @defaults %{
    loaded: true,
    flipping: false,
    flip_in: [],
    flip_out: []
  }
  defp assign_defaults(socket) do
    socket |> assign(@defaults)
  end

  def handle_event("animation-end", %{"target" => target}, socket) do
    socket
    |> exec_animation_end(target)
    |> noreply()
  end

  def handle_event("pick-card", %{"position" => position}, socket) do
    %{game: %Game{hand: hand}} = socket.assigns
    position = String.to_integer(position)
    card = hand |> Enum.at(position)

    socket
    |> assign(flipping: true, flip_out: [position])
    |> put_animation_end(card_id(card, position), fn socket ->
      socket
      |> assign(flipping: false, flip_out: [])
      |> activate_card(position)
    end)
    |> noreply()
  end

  defp activate_card(socket, position) do
    %{game: initial_game = game = %Game{hand: hand}} = socket.assigns

    card = hand |> Enum.at(position)
    game = Game.play_card(game, card)
    new_card = game.hand |> Enum.at(position)

    flip_in = card_positions_to_flip_in(initial_game, game)

    socket
    |> put_game(game)
    |> assign(flipping: true, flip_in: flip_in)
    |> put_animation_end(card_id(new_card, position), fn socket ->
      socket
      |> assign(flipping: false, flip_in: [])
    end)
  end

  defp card_positions_to_flip_in(%Game{hand: h1}, %Game{hand: h2}) do
    refs1 = h1 |> card_refs()
    refs2 = h2 |> card_refs()

    refs2
    |> Enum.with_index()
    |> Enum.reduce([], fn {ref, index}, acc ->
      if Enum.at(refs1, index) == ref do
        acc
      else
        [index | acc]
      end
    end)
  end

  defp card_refs(hand) do
    collector = hand |> Arrays.new() |> IntoArray.new()

    hand
    |> Enum.into(collector, fn
      nil -> nil
      card -> card.ref
    end)
  end

  defp put_game(socket, game) do
    socket
    |> assign(:game, game)
  end

  defp put_animation_end(socket = %{private: %{on_animation_end: on_animation_end}}, target, fun) do
    socket
    |> put_private(:on_animation_end, Map.put(on_animation_end, target, fun))
  end

  defp delete_animation_end(socket = %{private: %{on_animation_end: on_animation_end}}, target) do
    socket
    |> put_private(:on_animation_end, Map.delete(on_animation_end, target))
  end

  defp exec_animation_end(socket, target) do
    %{private: %{on_animation_end: on_animation_end}} = socket

    case Map.get(on_animation_end, target) do
      nil -> socket
      fun -> socket |> delete_animation_end(target) |> fun.()
    end
  end

  defp card_id(%Card{ref: ref}, _), do: "card_" <> ref
  defp card_id(nil, position), do: "card_empty_" <> Integer.to_string(position)
end
