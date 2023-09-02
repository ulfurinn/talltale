defmodule Talltale.JSONB do
  @moduledoc """
  Ecto type for storing more types directly in JSONB other than just maps.
  """

  # https://stackoverflow.com/questions/55579922/ecto-jsonb-array-and-map-cast-issue

  @behaviour Ecto.Type
  def type, do: :any

  # Provide custom casting rules.
  def cast(data)
      when is_list(data) or is_map(data) or is_number(data) or is_binary(data) or
             data in [nil, true, false] do
    {:ok, data}
  end

  # Everything else is a failure though
  def cast(_), do: :error

  # When loading data from the database, we are guaranteed to
  # receive a map or list
  def load(data)
      when is_list(data) or is_map(data) or is_number(data) or is_binary(data) or
             data in [nil, true, false] do
    {:ok, data}
  end

  # When dumping data to the database, we *expect* a map or list
  # so we need to guard against them.
  def dump(data)
      when is_list(data) or is_map(data) or is_number(data) or is_binary(data) or
             data in [nil, true, false],
      do: {:ok, data}

  def dump(_), do: :error

  def embed_as(_), do: :self

  def equal?(x, x), do: true
  def equal?(_, _), do: false
end
