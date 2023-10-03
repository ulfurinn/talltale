defmodule TalltaleWeb.EditorLive.Deck do
  use TalltaleWeb, [:live_view, mode: :editor]

  alias Talltale.Editor.Deck
  alias Talltale.Editor.Tale

  def mount(_params = %{"tale" => tale_id, "id" => deck_id}, _session, socket) do
    socket
    |> setup(tale_id, :decks)
    |> then(&put_deck(&1, Tale.get_deck(tale(&1), id: deck_id)))
    |> then(&stream(&1, :cards, deck(&1).cards))
    |> ok
  end

  def handle_params(params, _, socket = %{assigns: %{live_action: live_action}}) do
    socket
    |> apply_action(params, live_action)
    |> noreply()
  end

  defp apply_action(socket, params, action)
  defp apply_action(socket, _, :edit), do: socket

  defp apply_action(socket, _, :new_card) do
    socket
    |> assign(:card, deck(socket) |> Deck.build_card())
  end

  defp apply_action(socket, %{"card_id" => card_id}, :edit_card) do
    socket
    |> assign(:card, deck(socket) |> Deck.get_card(id: card_id))
  end

  def handle_info({:deck_updated, deck}, socket) do
    socket
    |> put_deck(deck)
    |> noreply()
  end

  def handle_info({:card_created, card}, socket) do
    socket
    |> stream_insert(:cards, card)
    |> noreply()
  end

  def handle_info({:card_updated, card}, socket) do
    socket
    |> stream_insert(:cards, card)
    |> noreply()
  end

  def handle_info(_, socket), do: noreply(socket)
end
