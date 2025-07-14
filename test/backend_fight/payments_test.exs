defmodule BackendFight.PaymentsTest do
  use ExUnit.Case, async: true

  import Mox

  alias BackendFight.Payments
  alias Ecto.UUID
  alias BackendFight.RedisMock

  setup :verify_on_exit!

  @valid_uuid UUID.generate()
  @valid_amount "19.90"

  describe "enqueue_payment/1" do
    test "successfully enqueues payment with valid data" do
      expect(RedisMock, :command, fn :redix, ["LPUSH", "payments_created", payload] ->
        decoded = Jason.decode!(payload)
        assert decoded["correlationId"] == @valid_uuid
        assert decoded["amount"] == 19.9
        {:ok, :queued}
      end)

      assert {:ok, :enqueued} =
               Payments.enqueue_payment(%{
                 "correlationId" => @valid_uuid,
                 "amount" => @valid_amount
               })
    end

    test "fails if correlationId is not a UUID" do
      assert {:error, :invalid_correlation_id} =
               Payments.enqueue_payment(%{
                 "correlationId" => "not-a-uuid",
                 "amount" => @valid_amount
               })
    end

    test "fails with invalid payload" do
      assert {:error, :invalid_payload} = Payments.enqueue_payment(%{"amount" => "10.0"})
      assert {:error, :invalid_payload} = Payments.enqueue_payment(%{})
      assert {:error, :invalid_payload} = Payments.enqueue_payment(nil)
    end
  end

  describe "purge_redis/0" do
    test "calls FLUSHDB on redis" do
      expect(RedisMock, :command, fn :redix, ["FLUSHDB"] ->
        {:ok, "OK"}
      end)

      assert {:ok, "OK"} = Payments.purge_redis()
    end
  end
end
