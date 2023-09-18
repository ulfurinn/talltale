defmodule Talltale.Game.Area do
  @moduledoc "A larger area containing several locations."
  use Talltale.Schema

  alias Talltale.Game.Deck
  alias Talltale.Game.Location
  alias Talltale.Game.Tale

  schema "areas" do
    field :title, :string

    belongs_to :tale, Tale
    has_many :locations, Location
    belongs_to :deck, Deck
  end
end
