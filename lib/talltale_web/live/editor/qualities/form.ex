defmodule TalltaleWeb.EditorLive.Quality.Form do
  use TalltaleWeb, [:live_component, mode: :editor]

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> put_form(Ecto.Changeset.change(assigns.quality))
    |> ok()
  end

  def handle_event("validate", %{"quality" => params}, socket = %{assigns: %{tale: tale}}) do
    quality = find_or_build_quality(tale, params)

    changeset =
      quality |> Quality.changeset(params) |> Map.put(:action, :validate)

    socket
    |> put_form(changeset)
    |> noreply()
  end

  def handle_event("save", %{"quality" => params}, socket = %{assigns: %{tale: tale}}) do
    quality = find_or_build_quality(tale, params)
    event = if quality.id == nil, do: :quality_created, else: :quality_updated

    result =
      quality
      |> Quality.changeset(params)
      |> Repo.insert_or_update()

    case result do
      {:ok, quality} ->
        notify_parent({event, quality})

        socket
        |> put_form(Ecto.Changeset.change(quality))
        |> maybe_patch()
        |> noreply()

      {:error, changeset} ->
        socket
        |> put_form(changeset)
        |> put_flash(:error, "Failed")
        |> noreply()
    end
  end

  defp find_or_build_quality(tale, %{"id" => id}), do: Tale.get_quality(tale, id: id)
  defp find_or_build_quality(tale, _), do: Tale.build_quality(tale)

  defp maybe_patch(socket = %{assigns: %{patch: url}}), do: socket |> push_patch(to: url)
  defp maybe_patch(socket), do: socket
end
