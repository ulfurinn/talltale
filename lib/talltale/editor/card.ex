defmodule Talltale.Editor.Card do
  @moduledoc "An action."
  use Talltale.Schema

  import Ecto.Changeset

  alias Talltale.Editor.Deck
  alias Talltale.Editor.Effect
  alias Talltale.Editor.Storylet

  schema "cards" do
    field :title, :string
    field :note, :string
    field :frequency, :integer, default: 1
    field :condition, :string
    field :sticky, :boolean, default: false

    embeds_many :effect, Effect

    belongs_to :deck, Deck
    belongs_to :storylet, Storylet
  end

  def changeset(area, attrs) do
    area
    |> cast(attrs, [:title, :note, :frequency, :condition, :sticky])
    |> validate_required([:title, :frequency])
    |> cast_embed(:effect,
      sort_param: :effect_order,
      with: &Effect.changeset/2
    )
  end
end
