defmodule EnumEx do
  def replace(enum, predicate, new_value) do
    enum
    |> Enum.map(fn item ->
      case predicate.(item) do
        true -> new_value
        false -> item
      end
    end)
  end
end
