defmodule TallTale.Repo.Migrations.AddPublishedFlag do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :published, :boolean, default: false
    end
  end
end
