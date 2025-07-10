defmodule BackendFight.Clients.PaymentProcessors.PaymentParams do
  use Ecto.Schema

  alias Ecto.UUID

  import Ecto.Changeset

  @permitted_params ~w(correlationId amount requestedAt)a
  @required_fields ~w(correlationId amount requestedAt)a

  @primary_key false
  embedded_schema do
    field :correlationId, UUID
    field :amount, :float
    field :requestedAt, :string
  end

  def changeset(params) do
    %__MODULE__{}
    |> cast(params, @permitted_params)
    |> validate_required(@required_fields)
    |> validate_number(:amount, greater_than: 0)
  end
end
