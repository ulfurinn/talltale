defmodule Talltale.Editor.Card do
  @moduledoc "An action."
  use Talltale.Schema

  import Ecto.Changeset

  alias Talltale.Editor.Deck
  alias Talltale.Editor.Effect

  schema "cards" do
    field :slug, :string
    field :title, :string
    field :frequency, :integer

    embeds_many :effect, Effect, on_replace: :delete

    belongs_to :deck, Deck
  end

  def changeset(area, attrs) do
    area
    |> cast(attrs, [:slug, :title, :frequency])
    |> validate_required([:slug, :title, :frequency])
    |> cast_embed(:effect, required: true, sort_param: :effect_order, with: &Effect.changeset/2)
  end
end
