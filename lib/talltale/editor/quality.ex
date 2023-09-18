defmodule Talltale.Editor.Quality do
  @moduledoc "A game state quality definition."
  use Talltale.Schema

  import Ecto.Changeset

  alias Talltale.Editor.Tale

  schema "qualities" do
    field :slug, :string
    field :type, :string
    field :category, :string
    field :title, :string
    field :description, :string

    belongs_to :tale, Tale
  end

  def changeset(quality, attrs) do
    quality
    |> cast(attrs, [:slug, :title, :type, :category, :tale_id])
    |> validate_required([:slug, :title, :type, :category, :tale_id])
  end
end
