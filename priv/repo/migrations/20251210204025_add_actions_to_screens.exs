defmodule TallTale.Repo.Migrations.AddActionsToScreens do
  use Ecto.Migration

  def change do
    alter table(:screens) do
      add :actions, :jsonb, default: "[]", null: false
    end
  end
end
