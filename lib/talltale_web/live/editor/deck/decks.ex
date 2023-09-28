defmodule TalltaleWeb.EditorLive.Decks do
  use TalltaleWeb, [:live_view, mode: :editor]

  def mount(_params = %{"tale" => tale_id}, _session, socket) do
    socket
    |> setup(tale_id, :decks)
    |> then(&stream(&1, :decks, tale(&1).decks))
    |> ok
  end

  def handle_params(params, _, socket = %{assigns: %{live_action: live_action}}) do
    socket
    |> apply_action(params, live_action)
    |> noreply()
  end

  defp apply_action(socket, params, action)

  defp apply_action(socket, _, :new) do
    socket
    |> assign(:deck, socket |> tale() |> Tale.build_deck())
  end

  defp apply_action(socket, _, _), do: socket

  def handle_info({:deck_created, deck}, socket) do
    socket
    |> stream_insert(:decks, deck)
    |> noreply()
  end
end
