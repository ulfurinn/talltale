defmodule TalltaleWeb.EditorLive.Quality do
  use Phoenix.Component

  import Phoenix.LiveView
  import TalltaleWeb.EditorLive.Common
  import TalltaleWeb.LiveHelpers
  import TalltaleWeb.LiveHelpers.Editor

  alias Talltale.Editor.Quality
  alias Talltale.Editor.Tale
  alias Talltale.Repo

  def handle_event("new", _, socket = %{assigns: %{tale: tale}}) do
    quality = Ecto.build_assoc(tale, :qualities)

    socket
    |> put_change_action("quality.validate")
    |> put_submit_action("quality.save")
    |> put_changeset(Ecto.Changeset.change(quality))
    |> noreply()
  end

  def handle_event("edit", %{"id" => id}, socket = %{assigns: %{tale: tale}}) do
    quality = Tale.get_quality(tale, id: id)

    socket
    |> put_change_action("quality.validate")
    |> put_submit_action("quality.save")
    |> put_changeset(Ecto.Changeset.change(quality))
    |> noreply()
  end

  def handle_event("validate", %{"quality" => params}, socket = %{assigns: %{tale: tale}}) do
    quality = find_or_build_quality(tale, params)

    changeset =
      quality |> Quality.changeset(params) |> Map.put(:action, :validate)

    socket
    |> put_changeset(changeset)
    |> noreply()
  end

  def handle_event("save", %{"quality" => params}, socket = %{assigns: %{tale: tale}}) do
    quality = find_or_build_quality(tale, params)

    result =
      quality
      |> Quality.changeset(params)
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

  defp find_or_build_quality(tale, %{"id" => id}), do: Tale.get_quality(tale, id: id)
  defp find_or_build_quality(tale, _), do: Ecto.build_assoc(tale, :qualities)
end
