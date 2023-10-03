defmodule TalltaleWeb.EditorLive do
  use TalltaleWeb, [:live_view, mode: :editor]

  import TalltaleWeb.EditorLive.Common

  alias Talltale.Editor.Tale
  alias Talltale.Repo

  embed_templates "editor/*"

  def mount(params, _session, socket) do
    case params do
      %{"tale" => id} ->
        tale = Repo.load_tale_for_editing(id)

        socket
        |> assign(:theme, "editor")
        |> put_tale(tale)
        |> put_tales(nil)
        |> put_tabs(tabs(tale))
        |> put_change_action("tale.change")
        |> put_submit_action("tale.update")
        |> put_changeset(Ecto.Changeset.change(tale))
        |> ok()

      _ ->
        tales = Repo.list_tales()

        socket
        |> assign(:theme, "editor")
        |> put_tales(tales)
        |> put_tabs(nil)
        |> put_changeset(Ecto.Changeset.change(%Tale{}))
        |> put_submit_action("tale.create")
        |> put_change_action("select_tale")
        |> ok()
    end
  end

  def handle_event("select_tab", %{"id" => id}, socket) do
    tab = String.to_existing_atom(id)

    changeset =
      case tab do
        :tale -> Ecto.Changeset.change(socket.assigns.tale)
        _ -> nil
      end

    socket
    |> put_current_tab(tab)
    |> put_changeset(changeset)
    |> then(fn socket ->
      if tab == :tale do
        socket
        |> put_submit_action("tale.create")
        |> put_change_action("select_tale")
      else
        socket
      end
    end)
    |> noreply()
  end

  def handle_event("select_tale", params, socket) do
    case params do
      %{"slug" => slug} ->
        socket
        |> redirect(to: ~p"/edit/#{slug}")
        |> noreply()

      _ ->
        socket
        |> noreply()
    end
  end

  def handle_event("tale." <> action, params, socket),
    do: TalltaleWeb.EditorLive.Tale.handle_event(action, params, socket)

  defp editor_form(assigns = %{changeset: %Ecto.Changeset{data: data}}) do
    case data do
      %Tale{} -> tale_form(assigns)
    end
  end

  defp editor_form(assigns), do: ~H""
end
