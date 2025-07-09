defmodule BackendFightWeb.PaymentControllerTest do
  use BackendFightWeb.ConnCase, async: true

  alias BackendFight.Schemas.Payment
  alias BackendFight.Repo

  describe "POST /payments" do
    test "creates a payment with valid data", %{conn: conn} do
      uuid = Ecto.UUID.generate()

      payload = %{
        "correlationId" => uuid,
        "amount" => 19.90
      }

      conn = post(conn, "/payments", payload)

      assert json_response(conn, 200) == %{"correlationId" => uuid}
      assert Repo.get(Payment, uuid)
    end

    test "returns 422 for missing fields", %{conn: conn} do
      conn = post(conn, "/payments", %{"correlationId" => Ecto.UUID.generate()})

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "returns 422 for invalid UUID", %{conn: conn} do
      conn = post(conn, "/payments", %{"correlationId" => "invalid", "amount" => 10.0})

      assert json_response(conn, 422)["error"] == "invalid_correlation_id"
    end

    test "returns 422 for negative amount", %{conn: conn} do
      conn =
        post(conn, "/payments", %{
          "correlationId" => Ecto.UUID.generate(),
          "amount" => -5
        })

      assert json_response(conn, 422)["errors"]["amount"] == ["must be greater than 0"]
    end
  end
end
