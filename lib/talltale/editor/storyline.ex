defmodule Talltale.Editor.Storyline do
  use Talltale.Schema

  import Ecto.Changeset

  embedded_schema do
    field :text, :string
    field :condition, :string
  end

  def changeset(storyline, attrs) do
    storyline
    |> cast(attrs, [:text, :condition])
    |> validate_required([:text])
  end
end
