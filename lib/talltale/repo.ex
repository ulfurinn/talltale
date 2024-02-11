defmodule Talltale.Repo do
  use Ecto.Repo,
    otp_app: :talltale,
    adapter: Ecto.Adapters.Postgres
end
