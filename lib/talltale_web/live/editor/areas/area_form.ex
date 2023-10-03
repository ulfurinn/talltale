defmodule TalltaleWeb.EditorLive.Area.AreaForm do
  use TalltaleWeb, [:live_component, mode: :editor]

  alias Talltale.Editor.Area
  alias Talltale.Editor.Tale

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> put_form(Ecto.Changeset.change(assigns.area))
    |> ok()
  end

  def handle_event("validate", %{"area" => params}, socket = %{assigns: %{tale: tale}}) do
    area = find_or_build_area(tale, params)

    changeset =
      area
      |> Area.changeset(params)
      |> Map.put(:action, :validate)

    socket
    |> put_form(changeset)
    |> noreply()
  end

  def handle_event("save", %{"area" => params}, socket = %{assigns: %{tale: tale}}) do
    area = find_or_build_area(tale, params)
    event = if area.id == nil, do: :area_created, else: :area_updated

    result =
      area
      |> Area.changeset(params)
      |> Repo.insert_or_update()

    case result do
      {:ok, area} ->
        notify_parent({event, area})

        socket
        |> put_form(Ecto.Changeset.change(area))
        |> maybe_patch()
        |> noreply()

      {:error, changeset} ->
        socket
        |> put_form(changeset)
        |> put_flash(:error, "Failed")
        |> noreply()
    end
  end

  defp find_or_build_area(tale, %{"id" => id}), do: Tale.get_area(tale, id: id)
  defp find_or_build_area(tale, _), do: Tale.build_area(tale)

  defp maybe_patch(socket = %{assigns: %{patch: url}}), do: socket |> push_patch(to: url)
  defp maybe_patch(socket), do: socket
end
