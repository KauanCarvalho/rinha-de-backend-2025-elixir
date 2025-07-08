defmodule BackendFight.Repo do
  use Ecto.Repo,
    otp_app: :backend_fight,
    adapter: Ecto.Adapters.Postgres
end
