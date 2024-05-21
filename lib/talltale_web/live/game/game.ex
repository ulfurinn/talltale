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
    animating: false,
    entered_storylet?: false,
    picked_card_position: nil,
    screen_fade_in: false,
    screen_fade_out: false,
    flip_in: [],
    flip_out: []
  }
  defp assign_defaults(socket) do
    socket |> assign(@defaults)
  end

  def handle_event("start", _, socket) do
    game = Game.new(socket.assigns.tale) |> Game.reshuffle()

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
    %{tale: tale} = socket.assigns
    game = Game.new(tale) |> Game.reshuffle()

    socket
    |> start(game)
    |> noreply()
  end

  def handle_event("reshuffle", _, socket) do
    %{game: game} = socket.assigns
    game = Game.reshuffle(game)

    socket
    |> put_game(game)
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
    |> assign(flip_out: [position])
    |> put_picked_card_position(position)
    |> put_animation_end(card_id(card, position), fn socket ->
      socket
      |> assign(flip_out: [])
      |> put_picked_card_position(nil)
      |> activate_card(position)
    end)
    |> noreply()
  end

  def handle_event("make-storylet-choice", %{"choice-id" => id}, socket) do
    %{game: game} = socket.assigns
    game = Game.play_storylet_choice(game, id)

    socket
    |> put_game(game)
    |> assign(:entered_outcome?, true)
    |> noreply()
  end

  def handle_event("dismiss-outcome", _, socket) do
    %{game: game} = socket.assigns
    game = Game.clear_outcome(game)

    socket
    |> put_game(game)
    |> assign(:entered_outcome?, false)
    |> noreply()
  end

  def handle_event("screen-proceed", _, socket) do
    %{game: game} = socket.assigns
    updated_game = Game.screen_proceed(game)

    socket
    |> assign(screen_fade_out: true)
    |> put_animation_end("screen", fn socket ->
      socket
      |> assign(screen_fade_out: false)
      |> put_game(updated_game)
      |> maybe_fade_in_scene(game)
    end)
    |> noreply()
  end

  def handle_event("set-quality", params = %{"_target" => [id]}, socket) do
    value = params[id]
    %{game: game} = socket.assigns
    game = game |> Game.put_quality(id, value)

    socket
    |> put_game(game)
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
    |> assign(flip_in: flip_in)
    |> assign(entered_storylet?: entered_storylet?(initial_game, game))
    |> assign(entered_outcome?: game.outcome != nil)
    |> put_animation_end(card_id(new_card, position), fn socket ->
      socket
      |> assign(flip_in: [])
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

  defp entered_screen?(%Game{qualities: qualities}, %Game{qualities: previous_qualities}) do
    qualities["screen"] && qualities["screen"] != previous_qualities["screen"]
  end

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
    |> assign(animating: true)
  end

  defp delete_animation_end(socket = %{private: %{on_animation_end: on_animation_end}}, target) do
    on_animation_end = Map.delete(on_animation_end, target)

    socket
    |> put_private(:on_animation_end, on_animation_end)
    |> assign(animating: not Enum.empty?(on_animation_end))
  end

  defp exec_animation_end(socket, target) do
    %{private: %{on_animation_end: on_animation_end}} = socket

    case Map.get(on_animation_end, target) do
      nil -> socket
      fun -> socket |> delete_animation_end(target) |> fun.()
    end
  end

  defp maybe_fade_in_scene(socket, previous_game) do
    %{game: game} = socket.assigns

    cond do
      entered_screen?(game, previous_game) ->
        socket
        |> assign(screen_fade_in: true)
        |> put_animation_end("screen", fn socket ->
          socket
          |> assign(screen_fade_in: false)
        end)

      true ->
        socket
    end
  end

  defp in_screen?(game) do
    game.qualities["screen"] != nil
  end

  defp card_id(%Card{ref: ref}, _), do: "card_" <> ref
  defp card_id(nil, position), do: "card_empty_" <> Integer.to_string(position)

  defp dynamic_style(game = %Game{}) do
    area = game.qualities["area"]
    file = List.to_string(:code.priv_dir(:talltale)) <> "/static/images/#{area}.jpg"

    if File.exists?(file) do
      "background-image: url('/images/#{area}.jpg')"
    else
      ""
    end
  end

  defp dynamic_style(_), do: ""
end
