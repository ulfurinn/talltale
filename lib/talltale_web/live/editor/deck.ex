defmodule TalltaleWeb.EditorLive.Deck do
  use Phoenix.Component

  import Phoenix.LiveView
  import TalltaleWeb.EditorLive.Common

  alias Talltale.Editor.Deck
  alias Talltale.Editor.Tale
  alias Talltale.Repo

  def handle_event("new", _, socket = %{assigns: %{tale: tale}}) do
    deck = Ecto.build_assoc(tale, :decks)

    socket
    |> put_change_action("deck.validate")
    |> put_submit_action("deck.save")
    |> put_changeset(Ecto.Changeset.change(deck))
    |> noreply()
  end

  def handle_event("edit", %{"id" => id}, socket = %{assigns: %{tale: tale}}) do
    deck = Tale.get_deck(tale, id: id)

    socket
    |> put_change_action("deck.validate")
    |> put_submit_action("deck.save")
    |> put_changeset(Ecto.Changeset.change(deck))
    |> noreply()
  end

  def handle_event("validate", %{"deck" => params}, socket = %{assigns: %{tale: tale}}) do
    deck = find_or_build_deck(tale, params)

    changeset =
      deck |> Deck.changeset(params) |> Map.put(:action, :validate)

    socket
    |> put_changeset(changeset)
    |> noreply()
  end

  def handle_event("save", %{"deck" => params}, socket = %{assigns: %{tale: tale}}) do
    deck = find_or_build_deck(tale, params)

    result =
      deck
      |> Deck.changeset(params)
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

  defp find_or_build_deck(tale, %{"id" => id}), do: Tale.get_deck(tale, id: id)
  defp find_or_build_deck(tale, _), do: Ecto.build_assoc(tale, :decks)
end
