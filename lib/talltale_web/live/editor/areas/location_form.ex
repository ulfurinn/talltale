defmodule TalltaleWeb.EditorLive.Area.LocationForm do
  use TalltaleWeb, [:live_component, mode: :editor]

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> put_form(Ecto.Changeset.change(assigns.location))
    |> ok()
  end

  def handle_event("validate", %{"location" => params}, socket) do
    changeset =
      socket
      |> tale()
      |> find_or_build_location(params)
      |> Location.changeset(params)
      |> Map.put(:action, :validate)

    socket
    |> put_form(changeset)
    |> noreply()
  end

  def handle_event("save", %{"location" => params}, socket = %{assigns: %{tale: tale}}) do
    location = find_or_build_location(tale, params)
    event = if location.id == nil, do: :location_created, else: :location_updated

    result =
      location
      |> Location.changeset(params)
      |> Repo.insert_or_update()

    case result do
      {:ok, location} ->
        notify_view({event, location})

        socket
        |> noreply()

      {:error, changeset} ->
        socket
        |> put_form(changeset)
        |> put_flash(:error, "Failed")
        |> noreply()
    end
  end

  defp find_or_build_location(tale, %{"area_id" => area_id, "id" => id}),
    do: tale |> Tale.get_area(id: area_id) |> Area.get_location(id: id)

  defp find_or_build_location(tale, %{"area_id" => area_id}),
    do: tale |> Tale.get_area(id: area_id) |> Area.build_location()
end
