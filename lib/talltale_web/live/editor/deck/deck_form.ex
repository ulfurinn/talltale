defmodule TalltaleWeb.EditorLive.Deck.DeckForm do
  use TalltaleWeb, [:live_component, mode: :editor]

  alias Talltale.Editor.Deck
  alias Talltale.Editor.Tale
  alias Talltale.Repo

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> put_form(Ecto.Changeset.change(assigns.deck))
    |> ok()
  end

  def handle_event("validate", %{"deck" => params}, socket = %{assigns: %{tale: tale}}) do
    deck = find_or_build_deck(tale, params)

    changeset =
      deck |> Deck.changeset(params) |> Map.put(:action, :validate)

    socket
    |> put_form(changeset)
    |> noreply()
  end

  def handle_event("save", %{"deck" => params}, socket = %{assigns: %{tale: tale}}) do
    deck = find_or_build_deck(tale, params)
    event = if deck.id == nil, do: :deck_created, else: :deck_updated

    result =
      deck
      |> Deck.changeset(params)
      |> Repo.insert_or_update()

    case result do
      {:ok, deck} ->
        notify_parent({event, deck})

        socket
        |> put_flash(:info, "Deck saved")
        |> put_form(Ecto.Changeset.change(deck))
        |> noreply()

      {:error, changeset} ->
        socket
        |> put_flash(:error, "Failed")
        |> put_form(changeset)
        |> noreply()
    end
  end

  defp find_or_build_deck(tale, %{"id" => id}), do: Tale.get_deck(tale, id: id)
  defp find_or_build_deck(tale, _), do: Tale.build_deck(tale)
end
