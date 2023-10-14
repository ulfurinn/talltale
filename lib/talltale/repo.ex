defmodule Talltale.Repo do
  use Ecto.Repo,
    otp_app: :talltale,
    adapter: Ecto.Adapters.Postgres

  import Ecto.Query, only: [from: 2]

  def list_tales do
    q = Talltale.Editor.Tale

    all(q)
  end

  def load_tale(slug) do
    assocs = all_assocs()

    q =
      from t in Talltale.Game.Tale,
        where: t.slug == ^slug,
        preload: ^assocs

    one(q)
  end

  def load_tale_for_editing(slug) do
    assocs = [:locations | all_assocs()]

    q =
      from t in Talltale.Editor.Tale,
        where: t.slug == ^slug,
        preload: ^assocs

    one(q)
  end

  def refresh(tale) do
    preload(tale, all_assocs(), force: true)
  end

  defp all_assocs do
    [
      :qualities,
      storylets: :cards,
      areas: [deck: :cards, locations: [deck: :cards]],
      decks: :cards
    ]
  end
end
