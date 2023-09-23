defmodule Talltale.Repo.Migrations.AddStickyToCard do
  use Ecto.Migration

  def change do
    alter table(:cards) do
      add :sticky, :boolean, default: false
    end
  end
end
