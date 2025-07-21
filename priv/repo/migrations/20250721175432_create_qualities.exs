defmodule TallTale.Repo.Migrations.CreateQualities do
  use Ecto.Migration

  def change do
    create table(:qualities) do
      add :game_id, references(:games, on_delete: :delete_all)
      add :name, :text
      add :identifier, :text
      timestamps()
    end
  end
end
