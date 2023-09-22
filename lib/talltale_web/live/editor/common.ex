defmodule TalltaleWeb.EditorLive.Common do
  use Phoenix.Component

  def put_tale(socket, tale) do
    socket
    |> assign(:tale, tale)
  end

  def put_tales(socket, tales) do
    socket
    |> assign(:tales, tales)
  end

  def put_change_action(socket, action) do
    socket
    |> assign(:change_action, action)
  end

  def put_submit_action(socket, action) do
    socket
    |> assign(:submit_action, action)
  end

  def put_changeset(socket, changeset) do
    socket
    |> assign(:changeset, changeset)
  end

  def put_tabs(socket, tabs) do
    socket
    |> assign(:tabs, tabs)
  end

  def put_current_tab(socket = %{assigns: %{tabs: tabs}}, id) do
    socket
    |> assign(:tabs, %{tabs | current: id})
  end

  def tabs do
    %{
      tabs: [
        tale: "Tale",
        qualities: "Qualities",
        areas: "Areas/Locations",
        cards: "Cards"
      ],
      current: :tale
    }
  end

  def effect_type_options do
    [
      {"Set quality", "set_quality"},
      {"Set area", "set_area"},
      {"Set location", "set_location"}
    ]
  end

  def locations_in_area(_tale, nil), do: []

  def locations_in_area(tale, area_id) do
    tale.areas
    |> Enum.find(&(&1.id == area_id))
    |> Map.get(:locations, [])
  end

  def ok(socket) do
    {:ok, socket}
  end

  def noreply(socket) do
    {:noreply, socket}
  end
end
