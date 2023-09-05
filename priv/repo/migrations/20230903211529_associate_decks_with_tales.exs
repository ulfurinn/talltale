defmodule Talltale.Repo.Migrations.AssociateDecksWithTales do
  use Ecto.Migration

  def change do
    alter table(:decks) do
      add :title, :string
      add :tale_id, references(:tales, type: :uuid, on_delete: :nothing)
    end
  end
end
