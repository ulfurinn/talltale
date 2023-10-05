defmodule Talltale.Repo.Migrations.AddNoteToCards do
  use Ecto.Migration

  def change do
    alter table(:cards) do
      add :note, :string
    end
  end
end
