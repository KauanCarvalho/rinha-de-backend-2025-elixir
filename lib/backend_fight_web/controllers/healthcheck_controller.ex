defmodule BackendFightWeb.HealthcheckController do
  use BackendFightWeb, :controller

  alias BackendFight.Repo

  def index(conn, _params) do
    redis = Application.get_env(:backend_fight, :redis_module, Redix)

    with {:ok, "PONG"} <- redis.command(:redix, ["PING"]),
         {:ok, _} <- Repo.query("SELECT 1") do
      json(conn, %{status: "ok"})
    else
      _ ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{status: "error"})
    end
  end
end
