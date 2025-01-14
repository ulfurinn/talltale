defmodule TallTale.Repo.Migrations.AddAccessCodes do
  use Ecto.Migration

  def change do
    create table(:access_codes) do
      add :code, :string
      add :game_id, references(:games, on_delete: :delete_all)
    end
  end
end
