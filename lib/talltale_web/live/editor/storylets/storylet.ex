defmodule TalltaleWeb.EditorLive.Storylet do
  use TalltaleWeb, [:live_view, mode: :editor]

  alias Talltale.Editor.Storylet
  alias Talltale.Editor.Tale

  def mount(_params = %{"tale" => tale_id, "id" => storylet_id}, _session, socket) do
    socket
    |> setup(tale_id, :storylets)
    |> then(&put_storylet(&1, Tale.get_storylet(tale(&1), id: storylet_id)))
    |> then(&stream(&1, :cards, storylet(&1).cards))
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
    |> assign(:card, storylet(socket) |> Storylet.build_card())
  end

  defp apply_action(socket, %{"card_id" => card_id}, :edit_card) do
    socket
    |> assign(:card, storylet(socket) |> Storylet.get_card(id: card_id))
  end

  def handle_info({:storylet_updated, storylet}, socket) do
    socket
    |> put_storylet(storylet)
    |> noreply()
  end

  def handle_info({:card_created, card}, socket) do
    socket
    |> put_storylet(socket |> storylet() |> then(&%{&1 | cards: &1.cards ++ [card]}))
    |> stream_insert(:cards, card)
    |> noreply()
  end

  def handle_info({:card_updated, card = %{id: id}}, socket) do
    socket
    |> put_storylet(
      socket
      |> storylet
      |> then(&%{&1 | cards: EnumEx.replace(&1.cards, fn c -> c.id == id end, card)})
    )
    |> put_card(
      case socket.assigns.card do
        %{id: ^id} -> card
        card -> card
      end
    )
    |> stream_insert(:cards, card)
    |> noreply()
  end

  def handle_info(_, socket), do: noreply(socket)
end
