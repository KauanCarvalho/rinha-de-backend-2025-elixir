defmodule BackendFight.PaymentsTest do
  use BackendFight.DataCase, async: true

  alias BackendFight.Payments
  alias BackendFight.Schemas.Payment
  alias BackendFight.Repo
  alias Ecto.{Changeset, UUID}

  describe "create_payment/1" do
    test "inserts a valid payment" do
      uuid = Ecto.UUID.generate()

      assert {:ok, %Payment{} = payment} =
               Payments.create_payment(%{
                 "correlationId" => uuid,
                 "amount" => 19.90
               })

      assert payment.correlation_id == uuid
      assert Decimal.eq?(payment.amount, Decimal.new("19.90"))
      assert payment.processor == :default
      assert payment.status == :created
      assert %DateTime{} = payment.requested_at

      assert Repo.get!(Payment, uuid)
    end

    test "returns :error for invalid UUID" do
      assert Payments.create_payment(%{
               "correlationId" => "invalid-uuid",
               "amount" => 10.0
             }) == {:error, :invalid_correlation_id}
    end

    test "returns error for missing fields" do
      assert {:error, :invalid_payload} =
               Payments.create_payment(%{
                 "correlationId" => UUID.generate()
               })
    end

    test "returns error for negative amount" do
      assert {:error, %Changeset{} = changeset} =
               Payments.create_payment(%{
                 "correlationId" => UUID.generate(),
                 "amount" => -5
               })

      assert %{amount: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "returns error for wrong types" do
      assert {:error, :invalid_payload} =
               Payments.create_payment(%{
                 "correlationId" => 123,
                 "amount" => "wrong"
               })
    end
  end
end
