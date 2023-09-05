defmodule Talltale.Editor.Effect do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  defmodule SetQuality do
    @moduledoc false
    use Ecto.Schema

    embedded_schema do
      field :quality, :string
      field :value, Talltale.JSONB
    end

    def changeset(effect, params) do
      effect
      |> cast(params, [:quality, :value])
      |> validate_required([:quality, :value])
    end
  end

  embedded_schema do
    field :type, :string, virtual: true
    embeds_one :set_quality, SetQuality, on_replace: :delete
  end

  def changeset(effect, params) do
    effect
    |> cast(params, [:type])
    |> reset_embeds()
    |> cast_for_type()
  end

  defp reset_embeds(changeset) do
    [:set_quality]
    |> Enum.reduce(changeset, &put_change(&2, &1, nil))
  end

  defp cast_for_type(changeset), do: cast_for_type(changeset, get_field(changeset, :type))

  defp cast_for_type(changeset, "set_quality") do
    changeset |> cast_embed(:set_quality, with: &SetQuality.changeset/2)
  end

  defp cast_for_type(changeset, _), do: changeset

  def type(%__MODULE__{set_quality: %{}}), do: "set_quality"
  def type(%__MODULE__{}), do: nil
end
