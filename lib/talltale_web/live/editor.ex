defmodule TalltaleWeb.EditorLive do
  use TalltaleWeb, [:live_view, layout: :editor]

  import TalltaleWeb.EditorLive.Common

  alias Talltale.Editor.Area
  alias Talltale.Editor.Location
  alias Talltale.Editor.Tale
  alias Talltale.Repo

  embed_templates "editor/*"

  def mount(_params, _session, socket) do
    case Repo.load_tale_for_editing("talltale") do
      nil ->
        tale = %Talltale.Editor.Tale{}

        socket
        |> put_tale(tale)
        |> put_tabs(tabs_for_new_tale())
        |> put_validate_action("tale.validate")
        |> put_submit_action("tale.create")
        |> put_changeset()
        |> ok()

      tale ->
        socket
        |> put_tale(tale)
        |> put_tabs(tabs_for_existing_tale())
        |> put_validate_action("tale.validate")
        |> put_submit_action("tale.update")
        |> put_changeset()
        |> ok()
    end
  end

  def handle_event("select_tab", %{"id" => id}, socket) do
    tab = String.to_existing_atom(id)

    socket
    |> put_current_tab(tab)
    |> put_changeset()
    |> noreply()
  end

  def handle_event(_, params = %{"_event" => event}, socket) when event != "",
    do: handle_event(event, Map.delete(params, "_event"), socket)

  def handle_event("tale." <> action, params, socket),
    do: TalltaleWeb.EditorLive.Tale.handle_event(action, params, socket)

  def handle_event("area." <> action, params, socket),
    do: TalltaleWeb.EditorLive.Area.handle_event(action, params, socket)

  def handle_event("location." <> action, params, socket),
    do: TalltaleWeb.EditorLive.Location.handle_event(action, params, socket)

  defp editor_form(assigns = %{changeset: %Ecto.Changeset{data: data}}) do
    case data do
      %Tale{} -> tale_form(assigns)
      %Area{} -> area_form(assigns)
      %Location{} -> location_form(assigns)
    end
  end

  defp editor_form(assigns), do: ~H""
end
