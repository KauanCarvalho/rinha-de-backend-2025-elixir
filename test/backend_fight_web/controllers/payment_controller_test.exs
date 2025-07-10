defmodule BackendFightWeb.PaymentControllerTest do
  use BackendFightWeb.ConnCase, async: true

  import Mox
  alias BackendFight.RedisMock
  alias Ecto.UUID

  setup :verify_on_exit!

  @valid_uuid UUID.generate()

  describe "POST /payments" do
    test "returns 202 on valid payload", %{conn: conn} do
      expect(RedisMock, :command, fn :redix, ["LPUSH", "payments_created", _payload] ->
        {:ok, :queued}
      end)

      conn =
        post(conn, "/payments", %{
          "correlationId" => @valid_uuid,
          "amount" => "10.0"
        })

      assert response(conn, 202) == ""
    end

    test "returns 422 for invalid UUID", %{conn: conn} do
      conn =
        post(conn, "/payments", %{
          "correlationId" => "invalid",
          "amount" => "10.0"
        })

      assert json_response(conn, 422)["error"] =~ "invalid_correlation_id"
    end

    test "returns 422 for malformed payload", %{conn: conn} do
      conn = post(conn, "/payments", %{})
      assert json_response(conn, 422)["error"] =~ "invalid_payload"
    end
  end

  describe "POST /purge-payments" do
    test "returns 200 when Redis is purged successfully", %{conn: conn} do
      expect(RedisMock, :command, fn :redix, ["FLUSHDB"] -> {:ok, "OK"} end)

      conn = post(conn, "/purge-payments")
      assert json_response(conn, 200)["message"] =~ "Redis cache purged successfully"
    end

    test "returns 500 on Redis error", %{conn: conn} do
      expect(RedisMock, :command, fn :redix, ["FLUSHDB"] -> {:error, :conn_err} end)

      conn = post(conn, "/purge-payments")
      body = json_response(conn, 500)
      assert body["error"] =~ "Failed to purge Redis"
      assert body["reason"] =~ ":conn_err"
    end
  end
end
