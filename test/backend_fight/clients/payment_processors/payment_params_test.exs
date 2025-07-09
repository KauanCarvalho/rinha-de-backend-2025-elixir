defmodule BackendFight.Clients.PaymentProcessors.PaymentParamsTest do
  use ExUnit.Case, async: true

  import Ecto.Changeset, only: [get_field: 2]

  alias BackendFight.Clients.PaymentProcessors.PaymentParams
  alias Ecto.UUID

  describe "changeset/1" do
    test "returns valid changeset with correct params" do
      params = %{
        "correlationId" => UUID.generate(),
        "amount" => "19.90",
        "requestedAt" => DateTime.utc_now() |> DateTime.truncate(:second)
      }

      changeset = PaymentParams.changeset(params)

      assert changeset.valid?
      assert get_field(changeset, :correlationId) == params["correlationId"]
      assert get_field(changeset, :amount) == 19.9
    end

    test "returns errors when required fields are missing" do
      changeset = PaymentParams.changeset(%{})

      refute changeset.valid?

      errors = errors_on(changeset)

      assert errors[:correlationId] == ["can't be blank"]
      assert errors[:amount] == ["can't be blank"]
      assert errors[:requestedAt] == ["can't be blank"]
    end

    test "returns error when amount is not greater than 0" do
      params = %{
        "correlationId" => UUID.generate(),
        "amount" => "0.00",
        "requestedAt" => DateTime.utc_now()
      }

      changeset = PaymentParams.changeset(params)

      refute changeset.valid?

      assert Enum.any?(errors_on(changeset)[:amount], fn msg ->
               String.starts_with?(msg, "must be greater than")
             end)
    end

    test "returns error for invalid types" do
      params = %{
        "correlationId" => "invalid-uuid",
        "amount" => "abc",
        "requestedAt" => "not-a-date"
      }

      changeset = PaymentParams.changeset(params)

      refute changeset.valid?

      errors = errors_on(changeset)

      assert errors[:correlationId] == ["is invalid"]
      assert errors[:amount] == ["is invalid"]
      assert errors[:requestedAt] == ["is invalid"]
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
