defmodule TalltaleWeb.EditorLive.Areas do
  use TalltaleWeb, [:live_view, mode: :editor]

  def mount(%{"tale" => tale_id}, _, socket) do
    socket
    |> setup(tale_id, :areas)
    |> then(&stream(&1, :areas, tale(&1).areas))
    |> ok
  end

  def handle_params(params, _, socket = %{assigns: %{live_action: live_action}}) do
    socket
    |> apply_action(params, live_action)
    |> noreply()
  end

  defp apply_action(socket, _, :new) do
    socket
    |> put_area(tale(socket) |> Tale.build_area())
  end

  defp apply_action(socket, _params, _action) do
    socket
  end

  def handle_info({:area_created, area}, socket) do
    socket
    |> stream_insert(:areas, area)
    |> noreply()
  end
end
