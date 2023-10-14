defmodule TalltaleWeb.EditorLive.Tale.Form do
  use TalltaleWeb, [:live_component, mode: :editor]

  import Phoenix.LiveView
  import TalltaleWeb.LiveHelpers
  import TalltaleWeb.LiveHelpers.Editor

  alias Talltale.Editor.Tale
  alias Talltale.Repo

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> put_form(Ecto.Changeset.change(assigns.tale))
    |> ok()
  end

  def handle_event("validate", %{"tale" => params}, socket = %{assigns: %{tale: tale}}) do
    params = transpose_start(params)
    changeset = tale |> Tale.changeset(params) |> Map.put(:action, :validate)

    socket
    |> put_form(changeset)
    |> noreply()
  end

  def handle_event("save", %{"tale" => params}, socket = %{assigns: %{tale: tale}}) do
    params = transpose_start(params)
    changeset = Tale.changeset(tale, params)

    case Repo.update(changeset) do
      {:ok, tale} ->
        socket
        |> put_tale(tale)
        |> put_form(Ecto.Changeset.change(tale))
        |> put_flash(:info, "Saved")
        |> redirect_if_slug_changed(changeset)
        |> noreply()

      {:error, changeset} ->
        socket
        |> put_form(changeset)
        |> put_flash(:error, "Failed")
        |> noreply()
    end
  end

  defp redirect_if_slug_changed(socket, %Ecto.Changeset{changes: %{slug: new_slug}}) do
    socket
    |> push_navigate(to: ~p"/edit/#{new_slug}")
  end

  defp redirect_if_slug_changed(socket, _changeset), do: socket

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
