defmodule Talltale.Editor.Effect do
  @moduledoc false
  use Talltale.Schema

  import Ecto.Changeset

  defmodule SetQuality do
    @moduledoc false
    use Ecto.Schema

    embedded_schema do
      field :expression, :string
    end

    def changeset(effect, params) do
      effect
      |> cast(params, [:expression])
      |> validate_required([:expression])
    end
  end

  embedded_schema do
    field :type, :string, virtual: true
    field :delete, :boolean, virtual: true
    embeds_one :set_quality, SetQuality
  end

  def changeset(effect, %{"delete" => _}) do
    effect
    |> change()
    |> put_change(:delete, true)
    |> Map.put(:action, :delete)
  end

  def changeset(effect, params) do
    effect
    |> cast(params, [:type])
    |> reset_embeds()
    |> cast_for_type()
  end

  defp reset_embeds(changeset) do
    [:set_quality]
    |> Enum.reduce(changeset, fn field, changeset ->
      value = get_field(changeset, field)

      case value do
        nil -> changeset
        value -> put_embed(changeset, field, Map.put(value, :action, :delete))
      end
    end)
  end

  defp cast_for_type(changeset), do: cast_for_type(changeset, get_field(changeset, :type))

  defp cast_for_type(changeset, nil) do
    changeset
  end

  defp cast_for_type(changeset, "set_quality") do
    changeset |> cast_embed(:set_quality, with: &SetQuality.changeset/2)
  end

  defp cast_for_type(_, type), do: raise("unknown effect #{type}")

  def type(%__MODULE__{set_quality: %{}}), do: "set_quality"
  def type(%__MODULE__{}), do: nil
end
