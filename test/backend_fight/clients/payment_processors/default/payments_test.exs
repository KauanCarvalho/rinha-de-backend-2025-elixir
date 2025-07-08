defmodule BackendFight.Clients.PaymentProcessors.Default.PaymentsTest do
  use ExUnit.Case

  alias BackendFight.Clients.PaymentProcessors.Default.Payments

  setup do
    bypass = Bypass.open(port: 9_001)
    {:ok, bypass: bypass}
  end

  test "returns :ok with valid response", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/payments/service-health", fn conn ->
      Plug.Conn.resp(conn, 200, ~s({"failing": false, "minResponseTime": 123}))
    end)

    assert {:ok, %{failing: false, min_response_time: 123}} = Payments.service_health()
  end

  test "returns error for unexpected response structure (200 but missing fields)", %{
    bypass: bypass
  } do
    Bypass.expect_once(bypass, "GET", "/payments/service-health", fn conn ->
      Plug.Conn.resp(conn, 200, ~s({"unexpected": "data"}))
    end)

    assert {:error, {:unexpected_response, %{"unexpected" => "data"}}} = Payments.service_health()
  end

  test "returns error for non-200 status", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/payments/service-health", fn conn ->
      Plug.Conn.resp(conn, 500, "Internal Server Error")
    end)

    assert {:error, {:unexpected_status, 500}} = Payments.service_health()
  end
end
