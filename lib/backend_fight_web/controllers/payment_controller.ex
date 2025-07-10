defmodule BackendFightWeb.PaymentController do
  use BackendFightWeb, :controller

  action_fallback BackendFightWeb.FallbackController

  alias BackendFight.Payments

  def create(conn, params) do
    with {:ok, _payment} <- Payments.enqueue_payment(params) do
      send_resp(conn, 202, "")
    end
  end

  def purge(conn, _params) do
    case Payments.purge_redis() do
      {:ok, _} ->
        json(conn, %{message: "Redis cache purged successfully"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to purge Redis", reason: inspect(reason)})
    end
  end

  def summary(conn, params) do
    json(conn, Payments.get_summary(params))
  end
end
