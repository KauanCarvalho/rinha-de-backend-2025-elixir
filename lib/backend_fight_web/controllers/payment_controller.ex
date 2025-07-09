defmodule BackendFightWeb.PaymentController do
  use BackendFightWeb, :controller

  action_fallback BackendFightWeb.FallbackController

  alias BackendFight.Payments

  def create(conn, params) do
    with {:ok, payment} <- Payments.create_payment(params) do
      json(conn, %{correlationId: payment.correlation_id})
    end
  end
end
