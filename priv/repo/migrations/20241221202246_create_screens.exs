defmodule TallTale.Repo.Migrations.CreateScreens do
  use Ecto.Migration

  def change do
    create table(:screens) do
      add :game_id, references(:games, on_delete: :delete_all)
      add :name, :text
      timestamps()
    end
  end
end
