defmodule TalltaleWeb.EditorLive.Storylet.StoryletForm do
  use TalltaleWeb, [:live_component, mode: :editor]

  alias Talltale.Editor.Storylet
  alias Talltale.Editor.Tale
  alias Talltale.Repo

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> put_form(Ecto.Changeset.change(assigns.storylet))
    |> ok()
  end

  def handle_event("validate", %{"storylet" => params}, socket = %{assigns: %{tale: tale}}) do
    storylet = find_or_build_storylet(tale, params)

    changeset =
      storylet |> Storylet.changeset(params) |> Map.put(:action, :validate)

    socket
    |> put_form(changeset)
    |> noreply()
  end

  def handle_event("save", %{"storylet" => params}, socket = %{assigns: %{tale: tale}}) do
    storylet = find_or_build_storylet(tale, params)
    event = if storylet.id == nil, do: :storylet_created, else: :storylet_updated

    result =
      storylet
      |> Storylet.changeset(params)
      |> Repo.insert_or_update()

    case result do
      {:ok, storylet} ->
        notify_view({event, storylet})

        socket
        |> put_flash(:info, "Storylet saved")
        |> put_form(Ecto.Changeset.change(storylet))
        |> maybe_patch()
        |> noreply()

      {:error, changeset} ->
        socket
        |> put_flash(:error, "Failed")
        |> put_form(changeset)
        |> noreply()
    end
  end

  defp find_or_build_storylet(tale, %{"id" => id}), do: Tale.get_storylet(tale, id: id)
  defp find_or_build_storylet(tale, _), do: Tale.build_storylet(tale)

  defp maybe_patch(socket = %{assigns: %{patch: url}}), do: socket |> push_patch(to: url)
  defp maybe_patch(socket), do: socket
end
