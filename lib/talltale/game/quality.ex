defmodule Talltale.Game.Quality do
  @moduledoc "A game state quality definition."
  use Talltale.Schema

  alias Talltale.Game.Tale

  schema "qualities" do
    field :slug, :string
    field :type, :string
    field :category, :string
    field :title, :string
    field :description, :string

    belongs_to :tale, Tale
  end
end
