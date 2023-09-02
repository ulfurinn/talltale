defmodule TalltaleWeb.EditorLive.Tale do
  use Phoenix.Component

  import Phoenix.LiveView
  import TalltaleWeb.EditorLive.Common

  alias Talltale.Repo

  def handle_event("validate", %{"tale" => params}, socket = %{assigns: %{tale: tale}}) do
    params = transpose_start(params)
    changeset = tale |> Talltale.Editor.Tale.changeset(params) |> Map.put(:action, :validate)

    socket
    |> put_changeset(changeset)
    |> noreply()
  end

  def handle_event(_, %{"add" => _, "tale" => params}, socket = %{assigns: %{tale: tale}}) do
    params =
      case transpose_start(params) do
        params = %{"start" => start} ->
          Map.put(params, "start", [{"", ""} | start])

        params ->
          params
      end

    changeset =
      tale
      |> Talltale.Editor.Tale.changeset(params)
      |> Map.put(:action, :validate)

    socket
    |> put_changeset(changeset)
    |> noreply()
  end

  def handle_event(_, %{"delete" => key, "tale" => params}, socket = %{assigns: %{tale: tale}}) do
    # The implementation of FormData for changesets is unhelpful here: in a
    # scenario where we add and immediately remove a new pair, the changeset
    # will revert to an unchanged state, in which case f[:start] will take the
    # field value from the params, which will contain the snapshot that still
    # had the new pair. Which means that we have to do the removal already in
    # the params, because if we apply it later through put_change, the new pair
    # will effectively become unremovable.
    params =
      case transpose_start(params) do
        params = %{"start" => start} ->
          Map.put(params, "start", List.keydelete(start, key, 0))

        params ->
          params
      end

    changeset = tale |> Talltale.Editor.Tale.changeset(params) |> Map.put(:action, :validate)

    socket
    |> put_changeset(changeset)
    |> noreply()
  end

  def handle_event("create", %{"save" => _, "tale" => params}, socket = %{assigns: %{tale: tale}}) do
    params = transpose_start(params)
    changeset = Talltale.Editor.Tale.changeset(tale, params)

    case Repo.insert(changeset) do
      {:ok, tale} ->
        tale = Repo.refresh(tale)

        socket
        |> put_tale(tale)
        |> put_tabs(tabs_for_existing_tale())
        |> put_validate_action("tale.validate")
        |> put_submit_action("tale.update")
        |> put_changeset()
        |> put_flash(:info, "Saved")
        |> noreply()

      {:error, changeset} ->
        socket
        |> put_changeset(changeset)
        |> put_flash(:error, "Failed")
        |> noreply()
    end
  end

  def handle_event("update", %{"save" => _, "tale" => params}, socket = %{assigns: %{tale: tale}}) do
    params = transpose_start(params)
    changeset = Talltale.Editor.Tale.changeset(tale, params)

    case Repo.update(changeset) do
      {:ok, tale} ->
        tale = Repo.refresh(tale)

        socket
        |> put_tale(tale)
        |> put_tabs(tabs_for_existing_tale())
        |> put_validate_action("tale.validate")
        |> put_submit_action("tale.update")
        |> put_changeset()
        |> put_flash(:info, "Saved")
        |> noreply()

      {:error, changeset} ->
        socket
        |> put_changeset(changeset)
        |> put_flash(:error, "Failed")
        |> noreply()
    end
  end

  defp transpose_start(%{"start" => start} = params) do
    start =
      start["key"]
      |> Enum.zip(start["value"])
      |> Enum.map(fn {k, v} ->
        case Integer.parse(v) do
          {v, ""} -> {k, v}
          _ -> {k, v}
        end
      end)

    Map.put(params, "start", start)
  end

  defp transpose_start(params), do: Map.put(params, "start", [])
end
