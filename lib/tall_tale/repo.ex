defmodule TallTale.Repo do
  use Ecto.Repo,
    otp_app: :tall_tale,
    adapter: Ecto.Adapters.SQLite3
end
