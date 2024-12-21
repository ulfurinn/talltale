defmodule TallTale.Store.Schema do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      @primary_key {:id, Uniq.UUID, version: 7, autogenerate: true}
      @foreign_key_type Uniq.UUID
      @timestamps_opts [type: :utc_datetime_usec]
    end
  end
end
