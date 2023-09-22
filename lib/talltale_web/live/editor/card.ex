defmodule TalltaleWeb.EditorLive.Card do
  use Phoenix.Component

  import Phoenix.LiveView
  import TalltaleWeb.EditorLive.Common

  alias Talltale.Editor.Card
  alias Talltale.Editor.Deck
  alias Talltale.Editor.Tale
  alias Talltale.Repo

  def handle_event("new", %{"deck_id" => deck_id}, socket = %{assigns: %{tale: tale}}) do
    deck = Tale.get_deck(tale, id: deck_id)
    card = Ecto.build_assoc(deck, :cards)

    socket
    |> put_change_action("card.validate")
    |> put_submit_action("card.save")
    |> put_changeset(Ecto.Changeset.change(card))
    |> noreply()
  end

  def handle_event("edit", params, socket = %{assigns: %{tale: tale}}) do
    card = find_or_build_card(tale, params)

    socket
    |> put_change_action("card.validate")
    |> put_submit_action("card.save")
    |> put_changeset(Ecto.Changeset.change(card))
    |> noreply()
  end

  def handle_event("validate", %{"card" => params}, socket = %{assigns: %{tale: tale}}) do
    card = find_or_build_card(tale, params)

    changeset =
      card |> Card.changeset(params) |> Map.put(:action, :validate)

    dbg(changeset)

    socket
    |> put_changeset(changeset)
    |> noreply()
  end

  def handle_event("save", %{"card" => params}, socket = %{assigns: %{tale: tale}}) do
    card = find_or_build_card(tale, params)

    result =
      card
      |> Card.changeset(params)
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

  defp find_or_build_card(tale, params) do
    deck = Tale.get_deck(tale, id: params["deck_id"])

    case params do
      %{"id" => id} -> Deck.get_card(deck, id: id)
      _ -> Ecto.build_assoc(deck, :cards)
    end
  end
end
