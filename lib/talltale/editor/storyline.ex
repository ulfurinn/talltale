defmodule Talltale.Editor.Storyline do
  use Talltale.Schema

  import Ecto.Changeset

  embedded_schema do
    field :text, :string
    field :condition, :string

    field :delete, :boolean, virtual: true
  end

  def changeset(storyline, %{"delete" => _}) do
    storyline
    |> change()
    |> put_change(:delete, true)
    |> Map.put(:action, :delete)
  end

  def changeset(storyline, attrs) do
    storyline
    |> cast(attrs, [:text, :condition])
    |> validate_required([:text])
  end
end
