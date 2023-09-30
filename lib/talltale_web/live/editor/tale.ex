defmodule TalltaleWeb.EditorLive.Tale do
  use TalltaleWeb, :html

  import Phoenix.LiveView
  import TalltaleWeb.EditorLive.Common
  import TalltaleWeb.LiveHelpers
  import TalltaleWeb.LiveHelpers.Editor

  alias Talltale.Editor.Tale
  alias Talltale.Repo

  def handle_event("change", %{"tale" => params}, socket = %{assigns: %{tale: tale}}) do
    params = transpose_start(params)
    changeset = tale |> Tale.changeset(params) |> Map.put(:action, :validate)

    socket
    |> put_changeset(changeset)
    |> noreply()
  end

  def handle_event("create", %{"save" => _, "tale" => params}, socket) do
    params = transpose_start(params)
    changeset = Tale.changeset(%Tale{}, params)

    case Repo.insert(changeset) do
      {:ok, tale} ->
        tale = Repo.refresh(tale)

        socket
        |> redirect(to: ~p"/edit/#{tale.slug}")
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
    changeset = Tale.changeset(tale, params)

    case Repo.update(changeset) do
      {:ok, tale} ->
        tale = Repo.refresh(tale)

        socket
        |> put_tale(tale)
        |> put_change_action("tale.change")
        |> put_submit_action("tale.update")
        |> put_changeset(Ecto.Changeset.change(tale))
        |> put_flash(:info, "Saved")
        |> noreply()

      {:error, changeset} ->
        socket
        |> put_changeset(changeset)
        |> put_flash(:error, "Failed")
        |> noreply()
    end
  end

  defp transpose_start(params = %{"start" => start, "start_order" => order}) do
    start =
      start["key"]
      |> Enum.zip(start["value"])
      |> Enum.map(fn {k, v} ->
        case Integer.parse(v) do
          {v, ""} -> {k, v}
          _ -> {k, v}
        end
      end)

    start =
      if Enum.count(order) > Enum.count(start) do
        start ++ [{"", ""}]
      else
        start
      end

    start =
      case params do
        %{"start_delete" => keys} ->
          Enum.reject(start, fn {k, _} -> k in keys end)

        _ ->
          start
      end

    Map.put(params, "start", start)
  end

  # no params, but something in the order list, so it's the "add quality" checkbox
  defp transpose_start(params = %{"start_order" => order}) when is_list(order) do
    start =
      if Enum.any?(order) do
        [{"", ""}]
      else
        []
      end

    Map.put(params, "start", start)
  end

  defp transpose_start(params), do: Map.put(params, "start", [])
end
