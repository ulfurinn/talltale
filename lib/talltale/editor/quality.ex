defmodule Talltale.Editor.Quality do
  use Talltale.Schema

  alias Talltale.Editor.Tale

  schema "qualities" do
    field :slug, :string
    field :type, :string
    field :category, :string
    field :title, :string
    field :description, :string

    belongs_to :tale, Tale
  end
end
