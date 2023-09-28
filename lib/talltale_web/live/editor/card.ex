defmodule TalltaleWeb.EditorLive.Card do
  use Phoenix.Component

  # def handle_event("new", %{"deck_id" => deck_id}, socket = %{assigns: %{tale: tale}}) do
  #   deck = Tale.get_deck(tale, id: deck_id)
  #   card = Ecto.build_assoc(deck, :cards)

  #   socket
  #   |> put_change_action("card.validate")
  #   |> put_submit_action("card.save")
  #   |> put_changeset(Ecto.Changeset.change(card))
  #   |> noreply()
  # end

  # def handle_event("edit", params, socket = %{assigns: %{tale: tale}}) do
  #   card = find_or_build_card(tale, params)

  #   socket
  #   |> put_change_action("card.validate")
  #   |> put_submit_action("card.save")
  #   |> put_changeset(Ecto.Changeset.change(card))
  #   |> noreply()
  # end
end
