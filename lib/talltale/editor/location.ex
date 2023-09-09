defmodule Talltale.Editor.Location do
  @moduledoc "A game location."
  use Talltale.Schema

  import Ecto.Changeset

  alias Talltale.Editor.Area
  alias Talltale.Editor.Deck
  alias Talltale.Editor.Storyline

  schema "locations" do
    field :slug, :string
    field :title, :string
    embeds_many :storyline, Storyline

    belongs_to :area, Area
    belongs_to :deck, Deck
  end

  def changeset(tale, attrs) do
    tale
    |> cast(attrs, [:slug, :title, :deck_id])
    |> validate_required([:slug, :title])
    |> cast_embed(:storyline,
      sort_param: :storyline_order,
      drop_param: :storyline_delete,
      with: &Storyline.changeset/2
    )
  end
end
