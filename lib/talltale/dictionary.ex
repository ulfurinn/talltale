defmodule Talltale.Dictionary do
  use Ecto.Type

  def type, do: :map

  def cast(data) when is_list(data) do
    {:ok, data}
  end

  def cast(data) when is_map(data) do
    {:ok, Enum.into(data, [])}
  end

  def load(data) do
    {:ok, Enum.into(data, [])}
  end

  def dump(data) do
    {:ok, Enum.into(data, %{})}
  end
end
