defmodule Talltale.Schema do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      @primary_key {:id, Uniq.UUID, version: 7, autogenerate: true}
      @foreign_key_type :binary_id
    end
  end
end
