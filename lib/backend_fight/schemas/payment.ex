defmodule BackendFight.Schemas.Payment do
  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Enum

  @permitted_params ~w(correlation_id amount processor requested_at status)a
  @required_fields ~w(correlation_id amount requested_at status)a
  @allowed_processors ~w(default fallback)a
  @allowed_statuses ~w(created processing completed failed)a

  @primary_key {:correlation_id, :binary_id, autogenerate: false}
  schema "payments" do
    field :amount, :decimal
    field :processor, Enum, values: @allowed_processors
    field :requested_at, :utc_datetime_usec
    field :status, Enum, values: @allowed_statuses
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @permitted_params)
    |> validate_required(@required_fields)
    |> validate_number(:amount, greater_than: 0)
    |> unique_constraint(:correlation_id, name: :payments_pkey)
  end
end
