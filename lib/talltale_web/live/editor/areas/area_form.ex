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

  def handle_event("save", %{"area" => params}, socket) do
    socket
    |> tale()
    |> find_or_build_area(params)
    |> Area.changeset(params)
    |> save(socket)
    |> handle_save_result(socket)
  end

  defp save(area, %{assigns: %{action: :new}}), do: Repo.insert(area)
  defp save(area, %{assigns: %{action: :edit}}), do: Repo.update(area)

  defp handle_save_result({:ok, area}, socket) do
    notify_view({event(socket), area})

    socket
    |> put_form(Ecto.Changeset.change(area))
    |> put_flash(:info, "Saved")
    |> maybe_patch()
    |> noreply()
  end

  defp handle_save_result({:error, changeset}, socket) do
    socket
    |> put_form(changeset)
    |> put_flash(:error, "Failed")
    |> noreply()
  end

  defp event(%{assigns: %{action: :new}}), do: :area_created
  defp event(%{assigns: %{action: :edit}}), do: :area_updated

  defp find_or_build_area(tale, %{"id" => id}), do: Tale.get_area(tale, id: id)
  defp find_or_build_area(tale, _), do: Tale.build_area(tale)

  defp maybe_patch(socket = %{assigns: %{patch: url}}), do: socket |> push_patch(to: url)
  defp maybe_patch(socket), do: socket
end
