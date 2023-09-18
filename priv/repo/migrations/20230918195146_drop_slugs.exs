defmodule Talltale.Repo.Migrations.DropSlugs do
  use Ecto.Migration

  def change do
    alter table(:areas) do
      remove :slug, :string
    end

    alter table(:locations) do
      remove :slug, :string
    end

    alter table(:cards) do
      remove :slug, :string
    end
  end
end
