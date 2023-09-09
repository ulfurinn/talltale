defmodule Talltale.Editor.Storyline do
  use Talltale.Schema

  embedded_schema do
    field :text, :string
    field :condition, :string
  end
end
