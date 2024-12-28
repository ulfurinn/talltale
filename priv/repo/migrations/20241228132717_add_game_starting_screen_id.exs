defmodule TallTale.Repo.Migrations.AddGameStartingScreenId do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :starting_screen_id, references(:screens, type: :uuid)
    end
  end
end
