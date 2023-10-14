defmodule Talltale.Repo.Migrations.AddStoryletToTale do
  use Ecto.Migration

  def change do
    alter table(:storylets) do
      add :tale_id, references(:tales, type: :uuid, on_delete: :nothing)
    end
  end
end
