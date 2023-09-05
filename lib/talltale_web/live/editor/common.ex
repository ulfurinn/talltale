defmodule TalltaleWeb.EditorLive.Common do
  use Phoenix.Component

  def put_tale(socket, tale) do
    socket
    |> assign(:tale, tale)
  end

  def put_change_action(socket, action) do
    socket
    |> assign(:change_action, action)
  end

  def put_submit_action(socket, action) do
    socket
    |> assign(:submit_action, action)
  end

  def put_changeset(socket) do
    put_changeset(socket, initial_tab_changeset(socket, socket.assigns.tabs.current))
  end

  def put_changeset(socket, changeset) do
    socket
    |> assign(:changeset, changeset)
  end

  def initial_tab_changeset(socket, :tale) do
    Ecto.Changeset.change(socket.assigns.tale)
  end

  def initial_tab_changeset(_, _) do
    nil
  end

  def put_tabs(socket, tabs) do
    socket
    |> assign(:tabs, tabs)
  end

  def put_current_tab(socket = %{assigns: %{tabs: tabs}}, id) do
    socket
    |> assign(:tabs, %{tabs | current: id})
  end

  def tabs_for_new_tale do
    %{
      tabs: [tale: "Tale"],
      current: :tale
    }
  end

  def tabs_for_existing_tale do
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
      {"Set quality", "set_quality"}
    ]
  end

  def effect_block(assigns = %{type: type}) do
    case type do
      nil ->
        ~H"<div></div>"

      "" ->
        ~H"<div></div>"

      type ->
        assigns =
          assigns
          |> assign(:type, String.to_existing_atom(type))
          |> assign(:component, String.to_existing_atom("effect_#{type}"))

        ~H"""
        <.inputs_for :let={effect} field={@effect[@type]}>
          <%= apply(__MODULE__, @component, [assign(assigns, :effect, effect)]) %>
        </.inputs_for>
        """
    end
  end

  def ok(socket) do
    {:ok, socket}
  end

  def noreply(socket) do
    {:noreply, socket}
  end
end
