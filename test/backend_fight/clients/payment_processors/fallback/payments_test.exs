defmodule BackendFight.Clients.PaymentProcessors.Fallback.PaymentsTest do
  use ExUnit.Case

  alias BackendFight.Clients.PaymentProcessors.Fallback.Payments
  alias Ecto.UUID

  setup do
    bypass = Bypass.open(port: 9_002)

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

  describe "create/1" do
    test "returns :ok with expected message", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/payments", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)

        assert is_binary(decoded["correlationId"])
        assert is_binary(decoded["requestedAt"])
        assert is_number(decoded["amount"])

        Plug.Conn.resp(conn, 200, ~s({"message": "payment processed successfully"}))
      end)

      params = %{
        "correlationId" => UUID.generate(),
        "amount" => 19.90,
        "requestedAt" => DateTime.utc_now()
      }

      assert {:ok, %{"message" => "payment processed successfully"}} = Payments.create(params)
    end

    test "returns error for unexpected response structure", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/payments", fn conn ->
        Plug.Conn.resp(conn, 200, ~s({"ok": true}))
      end)

      params = %{
        "correlationId" => UUID.generate(),
        "amount" => 10.00,
        "requestedAt" => DateTime.utc_now()
      }

      assert {:error, {:unexpected_response, _}} = Payments.create(params)
    end

    test "returns error for non-200 response", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/payments", fn conn ->
        Plug.Conn.resp(conn, 500, "Internal Server Error")
      end)

      params = %{
        "correlationId" => UUID.generate(),
        "amount" => 10.00,
        "requestedAt" => DateTime.utc_now()
      }

      assert {:error, {:unexpected_status, 500}} = Payments.create(params)
    end
  end
end
