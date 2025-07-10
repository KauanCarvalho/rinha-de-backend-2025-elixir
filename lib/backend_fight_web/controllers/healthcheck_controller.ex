defmodule BackendFightWeb.HealthcheckController do
  use BackendFightWeb, :controller

  def index(conn, _params) do
    redis = Application.get_env(:backend_fight, :redis_module, Redix)

    with {:ok, "PONG"} <- redis.command(:redix, ["PING"]) do
      json(conn, %{status: "ok"})
    else
      _ ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{status: "error"})
    end
  end
end
