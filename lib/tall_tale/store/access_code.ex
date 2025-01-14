defmodule TallTale.Store.AccessCode do
  use TallTale.Store.Schema

  schema "access_codes" do
    field :code, :string
    belongs_to :game, TallTale.Store.Game
  end
end
