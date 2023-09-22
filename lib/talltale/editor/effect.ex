defmodule Talltale.Editor.Effect do
  @moduledoc false
  use Talltale.Schema

  import Ecto.Changeset

  defmodule SetQuality do
    @moduledoc false
    use Talltale.Schema

    embedded_schema do
      field :expression, :string
    end

    def changeset(effect, params) do
      effect
      |> cast(params, [:expression])
      |> validate_required([:expression])
    end
  end

  defmodule SetLocation do
    @moduledoc false
    use Talltale.Schema

    embedded_schema do
      belongs_to :area, Talltale.Editor.Area
      belongs_to :location, Talltale.Editor.Location
    end

    def changeset(effect, params) do
      effect
      |> cast(params, [:area_id, :location_id])
      |> validate_required([:area_id, :location_id])
    end
  end

  embedded_schema do
    field :type, :string, virtual: true
    field :delete, :boolean, virtual: true
    embeds_one :set_quality, SetQuality
    embeds_one :set_location, SetLocation
  end

  def changeset(effect, %{"delete" => _}) do
    effect
    |> change()
    |> put_change(:delete, true)
    |> Map.put(:action, if(effect.id, do: :delete, else: :ignore))
  end

  def changeset(effect, params) do
    effect
    |> cast(params, [:type])
    |> reset_embeds()
    |> cast_for_type()
  end

  defp reset_embeds(changeset) do
    exclude =
      case Ecto.Changeset.get_field(changeset, :type) do
        nil -> []
        type -> [String.to_existing_atom(type)]
      end

    ([:set_quality, :set_location] -- exclude)
    |> Enum.reduce(changeset, fn field, changeset ->
      value = get_field(changeset, field)

      case value do
        nil ->
          changeset

        value ->
          action =
            if value.id do
              :delete
            else
              :ignore
            end

          value =
            value
            |> Ecto.Changeset.change()
            |> Map.put(:action, action)

          put_embed(changeset, field, value)
      end
    end)
    |> dbg
  end

  defp cast_for_type(changeset), do: cast_for_type(changeset, get_field(changeset, :type))

  defp cast_for_type(changeset, nil) do
    changeset
  end

  defp cast_for_type(changeset, "set_quality") do
    changeset
    |> cast_embed(:set_quality, with: &SetQuality.changeset/2)
  end

  defp cast_for_type(changeset, "set_location") do
    changeset
    |> cast_embed(:set_location, with: &SetLocation.changeset/2)
  end

  defp cast_for_type(_, type), do: raise("unknown effect #{type}")

  def type(changeset = %Ecto.Changeset{}),
    do: changeset |> Ecto.Changeset.apply_changes() |> type()

  def type(%__MODULE__{type: type}) when type != nil, do: type
  def type(%__MODULE__{set_quality: %{}}), do: "set_quality"
  def type(%__MODULE__{set_location: %{}}), do: "set_location"
  def type(%__MODULE__{}), do: nil
end
