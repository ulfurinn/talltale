defmodule Talltale.Editor.Area do
  @moduledoc "A larger area containing several locations."
  use Talltale.Schema

  import Ecto.Changeset

  alias Talltale.Editor.Deck
  alias Talltale.Editor.Location
  alias Talltale.Editor.Tale

  schema "areas" do
    field :slug, :string
    field :title, :string

    belongs_to :tale, Tale
    has_many :locations, Location
    belongs_to :deck, Deck
  end

  def changeset(area, attrs) do
    area
    |> cast(attrs, [:slug, :title])
    |> validate_required([:slug, :title])
  end

  def get_location(%__MODULE__{locations: locations}, id: id) do
    locations |> Enum.find(&(&1.id == id))
  end
end
