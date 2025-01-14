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

  def find_block(%__MODULE__{} = screen, block_id) do
    find_block(screen.blocks, block_id)
  end

  def find_block(blocks, id) do
    Enum.reduce_while(blocks, nil, fn block, acc ->
      cond do
        block["id"] == id ->
          {:halt, block}

        Map.has_key?(block, "row") ->
          subblocks = get_in(block, ["row", Access.key("blocks", [])])

          case find_block(subblocks, id) do
            nil -> {:cont, acc}
            block -> {:halt, block}
          end

        true ->
          {:cont, acc}
      end
    end)
  end
end
