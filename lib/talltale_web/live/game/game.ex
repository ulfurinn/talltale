defmodule TalltaleWeb.Game do
  @moduledoc false
  use TalltaleWeb, [:live_view, mode: :game]

  import TalltaleWeb.GameLive.HTML

  alias Talltale.Game
  alias Talltale.Game.Card
  alias Talltale.Game.Storylet
  # alias Talltale.Repo
  alias Talltale.Vault

  embed_templates "*"

  def mount(params, _session, socket) do
    socket
    |> assign(:theme, "game")
    |> assign(:loaded, false)
    |> then(fn socket ->
      if connected?(socket) do
        vault_root = List.to_string(:code.priv_dir(:talltale)) <> "/tales/" <> params["tale"]
        socket |> assign(tale: Vault.load(vault_root))
      else
        socket
      end
    end)
    |> ok()
  end

  @defaults %{
    loaded: true,
    flipping: false,
    entered_storylet?: false,
    picked_card_position: nil,
    flip_in: [],
    flip_out: []
  }
  defp assign_defaults(socket) do
    socket |> assign(@defaults)
  end

  def handle_event("start", _, socket) do
    game = Game.new(socket.assigns.tale)

    socket
    |> start(game)
    |> noreply()
  end

  def handle_event("restore", snapshot, socket) do
    game = Game.new(socket.assigns.tale) |> Game.restore(snapshot)

    socket
    |> start(game)
    |> noreply()
  end

  def handle_event("reset", _, socket) do
    game = Game.new(socket.assigns.tale)

    socket
    |> start(game)
    |> noreply()
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
    |> put_picked_card_position(position)
    |> put_animation_end(card_id(card, position), fn socket ->
      socket
      |> assign(flipping: false, flip_out: [])
      |> put_picked_card_position(nil)
      |> activate_card(position)
    end)
    |> noreply()
  end

  defp start(socket, game) do
    socket
    |> assign(:theme, "game")
    |> assign(:loaded, true)
    |> put_game(game)
    |> assign_defaults()
    |> put_private(:on_animation_end, %{})
  end

  defp activate_card(socket, position) do
    %{game: initial_game = game = %Game{hand: hand}} = socket.assigns

    card = hand |> Enum.at(position)
    game = Game.play_card(game, card)
    new_card = game.hand |> Enum.at(position)

    flip_in = card_positions_to_flip_in(initial_game, game)

    socket
    |> put_game(game)
    |> put_picked_card_position(position)
    |> assign(flipping: true, flip_in: flip_in)
    |> assign(entered_storylet?: entered_storylet?(initial_game, game))
    |> put_animation_end(card_id(new_card, position), fn socket ->
      socket
      |> assign(flipping: false, flip_in: [])
      |> put_picked_card_position(nil)
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

  defp entered_storylet?(%Game{storylet: nil}, %Game{storylet: %Storylet{}}), do: true
  defp entered_storylet?(_, _), do: false

  defp put_game(socket, game) do
    socket
    |> assign(:game, game)
    |> push_event("snapshot", Game.snapshot(game))
  end

  defp put_picked_card_position(socket, position) do
    socket
    |> assign(:picked_card_position, position)
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
