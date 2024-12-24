defmodule TallTale.Repo.Migrations.AddScreenFields do
  use Ecto.Migration

  def change do
    alter table(:screens) do
      add :blocks, :jsonb, default: "[]", null: false
    end
  end
end
