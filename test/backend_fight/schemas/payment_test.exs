defmodule BackendFight.Schemas.PaymentTest do
  use ExUnit.Case, async: true

  alias BackendFight.Schemas.Payment
  alias Ecto.UUID

  describe "changeset/2" do
    @valid_attrs %{
      "correlation_id" => UUID.generate(),
      "amount" => 19.90,
      "processor" => "default",
      "requested_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "status" => "created"
    }

    test "valid attributes produce a valid changeset" do
      changeset = Payment.changeset(%Payment{}, @valid_attrs)
      assert changeset.valid?
    end

    test "negative amount is invalid" do
      attrs = Map.put(@valid_attrs, "amount", -10.0)
      changeset = Payment.changeset(%Payment{}, attrs)
      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :amount)
    end

    test "invalid processor" do
      attrs = Map.put(@valid_attrs, "processor", "invalid")
      changeset = Payment.changeset(%Payment{}, attrs)
      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :processor)
    end

    test "invalid status" do
      attrs = Map.put(@valid_attrs, "status", "other")
      changeset = Payment.changeset(%Payment{}, attrs)
      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :status)
    end

    test "invalid requested_at format" do
      attrs = Map.put(@valid_attrs, "requested_at", "not-a-date")
      changeset = Payment.changeset(%Payment{}, attrs)
      assert changeset.valid?
    end

    test "missing required fields" do
      changeset = Payment.changeset(%Payment{}, %{})
      refute changeset.valid?

      required_fields = ~w(correlation_id amount requested_at status)a

      for field <- required_fields do
        assert Keyword.has_key?(changeset.errors, field)
      end
    end
  end
end
