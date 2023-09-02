defmodule Talltale.Repo.Migrations.Initial do
  use Ecto.Migration

  def change do
    create table(:tales, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :slug, :string
      add :title, :string
      add :start, :jsonb, default: "{}"
    end

    create index(:tales, [:slug], unique: true)

    create table(:decks, primary_key: false) do
      add :id, :uuid, primary_key: true
    end

    create table(:cards, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :slug, :string
      add :title, :string
      add :frequency, :integer
      add :effect, :jsonb
      add :tale_id, references(:tales, type: :uuid, on_delete: :nothing)
      add :deck_id, references(:decks, type: :uuid, on_delete: :nothing)
    end

    create index(:cards, [:tale_id, :slug], unique: true)

    create table(:areas, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :slug, :string
      add :title, :string
      add :tale_id, references(:tales, type: :uuid, on_delete: :nothing)
      add :deck_id, references(:decks, type: :uuid, on_delete: :nothing)
    end

    create index(:areas, [:tale_id, :slug], unique: true)

    create table(:locations, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :slug, :string
      add :title, :string
      add :storyline, :jsonb, default: "[]"
      add :area_id, references(:areas, type: :uuid, on_delete: :nothing)
      add :deck_id, references(:decks, type: :uuid, on_delete: :nothing)
    end

    create index(:locations, [:area_id, :slug], unique: true)

    create table(:qualities, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :slug, :string
      add :type, :string
      add :category, :string
      add :title, :string
      add :description, :string
      add :tale_id, references(:tales, type: :uuid, on_delete: :nothing)
    end

    create index(:qualities, [:tale_id, :slug], unique: true)
  end
end
