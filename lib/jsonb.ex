defmodule JSONB do
  use Ecto.Type

  def type, do: :jsonb

  defguard valid?(term)
           when is_list(term) or
                  is_map(term) or
                  is_number(term) or
                  is_atom(term) or
                  is_binary(term) or
                  is_boolean(term) or
                  is_nil(term)

  def cast(term) when valid?(term), do: {:ok, term}
  def cast(_), do: :error

  def load(term), do: JSON.decode(term)

  def dump(term) when valid?(term), do: {:ok, JSON.encode!(term)}
  def dump(_), do: :error
end
