defmodule TalltaleWeb.EditorLive.Area do
  use TalltaleWeb, [:live_view, mode: :editor]

  def mount(%{"tale" => tale_id, "id" => area_id}, _, socket) do
    socket
    |> setup(tale_id, :areas)
    |> then(&put_area(&1, Tale.get_area(tale(&1), id: area_id)))
    |> then(&stream(&1, :locations, area(&1).locations))
    |> ok
  end

  def handle_params(params, _, socket = %{assigns: %{live_action: live_action}}) do
    socket
    |> apply_action(params, live_action)
    |> noreply()
  end

  defp apply_action(socket, _, :edit), do: socket

  defp apply_action(socket, _, :new_location) do
    socket
    |> assign(:location, area(socket) |> Area.build_location())
  end

  defp apply_action(socket, %{"location_id" => location_id}, :edit_location) do
    socket
    |> assign(:location, area(socket) |> Area.get_location(id: location_id))
  end

  def handle_info({:area_updated, area}, socket) do
    socket
    |> put_area(area)
    |> noreply()
  end

  def handle_info({:location_created, location}, socket) do
    socket
    |> stream_insert(:locations, location)
    |> noreply()
  end

  def handle_info({:location_updated, location}, socket) do
    socket
    |> stream_insert(:locations, location)
    |> assign(:location, location)
    |> noreply()
  end
end
