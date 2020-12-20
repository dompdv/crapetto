defmodule Crapetto.Repo do
  use Ecto.Repo,
    otp_app: :crapetto,
    adapter: Ecto.Adapters.Postgres
end
