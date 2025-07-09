defmodule BackendFight.Schemas.PaymentTest do
  use ExUnit.Case, async: true

  alias BackendFight.Schemas.Payment

  describe "changeset/2" do
    @valid_attrs %{
      correlation_id: "4a7901b8-7d26-4d9d-aa19-4dc1c7cf60b3",
      amount: Decimal.new("19.90"),
      processor: :default,
      requested_at: ~U[2025-07-08 21:00:00Z],
      status: :created
    }

    test "valid attributes produce a valid changeset" do
      changeset = Payment.changeset(%Payment{}, @valid_attrs)
      assert changeset.valid?
    end

    test "negative amount is invalid" do
      attrs = Map.put(@valid_attrs, :amount, Decimal.new("-10.0"))
      changeset = Payment.changeset(%Payment{}, attrs)
      refute changeset.valid?
      assert Enum.any?(errors_on(changeset), fn {f, _} -> f == :amount end)
    end

    test "invalid processor" do
      attrs = Map.put(@valid_attrs, :processor, :invalid)
      changeset = Payment.changeset(%Payment{}, attrs)
      refute changeset.valid?
      assert Enum.any?(errors_on(changeset), fn {f, _} -> f == :processor end)
    end

    test "invalid status" do
      attrs = Map.put(@valid_attrs, :status, :other)
      changeset = Payment.changeset(%Payment{}, attrs)
      refute changeset.valid?
      assert Enum.any?(errors_on(changeset), fn {f, _} -> f == :status end)
    end

    test "invalid requested_at format" do
      attrs = Map.put(@valid_attrs, :requested_at, "not-a-date")
      changeset = Payment.changeset(%Payment{}, attrs)
      refute changeset.valid?
      assert Enum.any?(errors_on(changeset), fn {f, _} -> f == :requested_at end)
    end

    test "missing required fields" do
      changeset = Payment.changeset(%Payment{}, %{})
      refute changeset.valid?

      required_fields = ~w(correlation_id amount requested_at status)a

      for field <- required_fields do
        assert Enum.any?(errors_on(changeset), fn {f, _} -> f == field end)
      end
    end
  end

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
  end
end
