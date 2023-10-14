defmodule Talltale.Repo.Migrations.CreateStorylets do
  use Ecto.Migration

  def change do
    create table(:storylets, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :title, :text, null: false
      add :description, :text, null: false
    end

    alter table(:cards) do
      add :description, :text, null: true
      add :storylet_id, references(:storylets, type: :uuid, on_delete: :nothing)
    end
  end
end
