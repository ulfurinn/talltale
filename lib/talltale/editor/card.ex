defmodule Talltale.Editor.Card do
  @moduledoc "An action."
  use Talltale.Schema

  import Ecto.Changeset

  alias Talltale.Editor.Deck
  alias Talltale.Editor.Effect

  schema "cards" do
    field :title, :string
    field :note, :string
    field :frequency, :integer
    field :condition, :string
    field :sticky, :boolean, default: false

    embeds_many :effect, Effect

    belongs_to :deck, Deck
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
