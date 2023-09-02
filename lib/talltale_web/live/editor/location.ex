defmodule TalltaleWeb.EditorLive.Location do
  use Phoenix.Component

  import Phoenix.LiveView
  import TalltaleWeb.EditorLive.Common

  alias Talltale.Editor.Area
  alias Talltale.Editor.Location
  alias Talltale.Editor.Tale
  alias Talltale.Repo

  def handle_event("new", %{"area-id" => area_id}, socket = %{assigns: %{tale: tale}}) do
    area = Tale.get_area(tale, id: area_id)
    location = build_location(area)

    socket
    |> put_validate_action("location.validate")
    |> put_submit_action("location.save")
    |> put_changeset(Ecto.Changeset.change(location))
    |> noreply()
  end

  def handle_event(
        "edit",
        %{"area-id" => area_id, "id" => id},
        socket = %{assigns: %{tale: tale}}
      ) do
    area = Tale.get_area(tale, id: area_id)
    location = Area.get_location(area, id: id)

    socket
    |> put_validate_action("location.validate")
    |> put_submit_action("location.save")
    |> put_changeset(Ecto.Changeset.change(location))
    |> noreply()
  end

  def handle_event("add_storyline", %{"location" => params}, socket) do
    params =
      case params do
        %{"storyline" => storyline} ->
          Map.put(params, "storyline", storyline ++ [""])

        _ ->
          Map.put(params, "storyline", [""])
      end

    validate(params, socket)
  end

  def handle_event("validate", %{"location" => params}, socket) do
    validate(params, socket)
  end

  def handle_event("save", %{"location" => params}, socket = %{assigns: %{tale: tale}}) do
    area =
      tale
      |> Tale.get_area(id: params["area_id"])

    location = find_or_build_location(area, params)

    result =
      location
      |> Talltale.Editor.Location.changeset(params)
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

  defp validate(params, socket = %{assigns: %{tale: tale}}) do
    changeset =
      tale
      |> Tale.get_area(id: params["area_id"])
      |> find_or_build_location(params)
      |> Location.changeset(params)
      |> Map.put(:action, :validate)

    socket
    |> put_changeset(changeset)
    |> noreply()
  end

  defp find_or_build_location(area, %{"id" => id}), do: Area.get_location(area, id: id)
  defp find_or_build_location(area, _), do: build_location(area)

  defp build_location(area) do
    Ecto.build_assoc(area, :locations)
  end
end
