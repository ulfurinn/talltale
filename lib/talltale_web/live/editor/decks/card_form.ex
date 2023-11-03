defmodule TalltaleWeb.EditorLive.Deck.CardForm do
  use TalltaleWeb, [:live_component, mode: :editor]

  embed_templates "card_form/*"

  alias Talltale.Editor.Card
  alias Talltale.Editor.Deck
  alias Talltale.Editor.Tale

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> put_form(Ecto.Changeset.change(assigns.card))
    |> ok()
  end

  def handle_event("validate", %{"card" => params}, socket = %{assigns: %{tale: tale}}) do
    card = find_or_build_card(tale, params)

    changeset =
      card |> Card.changeset(params) |> Map.put(:action, :validate)

    socket
    |> put_form(changeset)
    |> noreply()
  end

  def handle_event("save", %{"card" => params}, socket = %{assigns: %{tale: tale}}) do
    card = find_or_build_card(tale, params)
    event = if card.id == nil, do: :card_created, else: :card_updated

    result =
      card
      |> Card.changeset(params)
      |> Repo.insert_or_update()

    case result do
      {:ok, card} ->
        notify_view({event, card})

        socket
        |> put_flash(:info, "Card saved")
        |> noreply()

      {:error, changeset} ->
        socket
        |> put_flash(:error, "Failed")
        |> put_form(changeset)
        |> noreply()
    end
  end

  defp find_or_build_card(tale, %{"deck_id" => deck_id, "id" => id}),
    do: tale |> Tale.get_deck(id: deck_id) |> Deck.get_card(id: id)

  defp find_or_build_card(tale, %{"deck_id" => deck_id}),
    do: tale |> Tale.get_deck(id: deck_id) |> Deck.build_card()

  defp effect_type_options do
    [
      {"Set quality", "set_quality"},
      {"Set area", "set_area"},
      {"Set location", "set_location"}
    ]
  end

  defp locations_in_area(_tale, nil), do: []

  defp locations_in_area(tale, area_id) do
    tale.areas
    |> Enum.find(&(&1.id == area_id))
    |> Map.get(:locations, [])
  end
end
