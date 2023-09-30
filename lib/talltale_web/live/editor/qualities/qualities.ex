defmodule TalltaleWeb.EditorLive.Qualities do
  use TalltaleWeb, [:live_view, mode: :editor]

  def mount(_params = %{"tale" => tale_id}, _session, socket) do
    socket
    |> setup(tale_id, :qualities)
    |> then(&stream(&1, :qualities, tale(&1).qualities))
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
    |> assign(:quality, socket |> tale() |> Tale.build_quality())
  end

  defp apply_action(socket, _, _), do: socket

  def handle_info({:quality_created, quality}, socket),
    do: socket |> stream_insert(:qualities, quality) |> noreply()
end
