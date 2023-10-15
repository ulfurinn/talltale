defmodule TalltaleWeb.EditorLive.Storylets do
  use TalltaleWeb, [:live_view, mode: :editor]

  def mount(_params = %{"tale" => tale_id}, _session, socket) do
    socket
    |> setup(tale_id, :storylets)
    |> then(&stream(&1, :storylets, tale(&1).storylets))
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
    |> assign(:storylet, socket |> tale() |> Tale.build_storylet())
  end

  defp apply_action(socket, _, _), do: socket

  def handle_info({:storylet_created, storylet}, socket) do
    socket
    |> stream_insert(:storylets, storylet)
    |> noreply()
  end
end
