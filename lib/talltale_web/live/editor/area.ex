defmodule TalltaleWeb.EditorLive.Area do
  use Phoenix.Component

  import Phoenix.LiveView
  import TalltaleWeb.EditorLive.Common

  alias Talltale.Editor.Area
  alias Talltale.Editor.Tale
  alias Talltale.Repo

  def handle_event("new", _, socket = %{assigns: %{tale: tale}}) do
    area = Ecto.build_assoc(tale, :areas)

    socket
    |> put_change_action("area.validate")
    |> put_submit_action("area.save")
    |> put_changeset(Ecto.Changeset.change(area))
    |> noreply()
  end

  def handle_event("edit", %{"id" => id}, socket = %{assigns: %{tale: tale}}) do
    area = Tale.get_area(tale, id: id)

    socket
    |> put_change_action("area.validate")
    |> put_submit_action("area.save")
    |> put_changeset(Ecto.Changeset.change(area))
    |> noreply()
  end

  def handle_event("validate", %{"area" => params}, socket = %{assigns: %{tale: tale}}) do
    area = find_or_build_area(tale, params)

    changeset =
      area |> Area.changeset(params) |> Map.put(:action, :validate)

    socket
    |> put_changeset(changeset)
    |> noreply()
  end

  def handle_event("save", %{"area" => params}, socket = %{assigns: %{tale: tale}}) do
    area = find_or_build_area(tale, params)

    result =
      area
      |> Area.changeset(params)
      |> Repo.insert_or_update()

    case result do
      {:ok, _} ->
        tale = Repo.refresh(tale)

        socket
        |> put_tale(tale)
        |> put_changeset(nil)
        |> noreply()

      {:error, changeset} ->
        socket
        |> put_changeset(changeset)
        |> put_flash(:error, "Failed")
        |> noreply()
    end
  end

  defp find_or_build_area(tale, %{"id" => id}), do: Tale.get_area(tale, id: id)
  defp find_or_build_area(tale, _), do: Ecto.build_assoc(tale, :areas)
end
