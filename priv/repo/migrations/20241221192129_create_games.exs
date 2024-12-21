defmodule TallTale.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :name, :text
      timestamps()
    end
  end
end
