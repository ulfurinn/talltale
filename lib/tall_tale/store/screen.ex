defmodule TallTale.Store.Screen do
  use TallTale.Store.Schema
  alias TallTale.Store.Game

  schema "screens" do
    field :name, :string
    belongs_to :game, Game

    field :blocks, JSONB, default: []

    timestamps()
  end

  @doc false
  def changeset(screen, attrs) do
    screen
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  def find_block(screen, block_id) do
    Enum.find(screen.blocks, &(&1["id"] == block_id))
  end
end
