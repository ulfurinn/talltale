defmodule Talltale.Repo.Migrations.AddConditionToCards do
  use Ecto.Migration

  def change do
    alter table(:cards) do
      add :condition, :string
    end
  end
end
