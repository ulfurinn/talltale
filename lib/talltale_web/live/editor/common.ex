defmodule TalltaleWeb.EditorLive.Common do
  use TalltaleWeb, :html

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

  def put_current_tab(socket = %{assigns: %{tabs: tabs}}, id) do
    socket
    |> assign(:tabs, %{tabs | current: id})
  end
end
