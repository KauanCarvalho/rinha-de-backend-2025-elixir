defmodule BackendFight.Schemas.Payment do
  use Ecto.Schema
  import Ecto.Changeset

  @permitted_params ~w(correlation_id amount processor requested_at status)a
  @required_fields ~w(correlation_id amount requested_at status)a
  @allowed_processors ~w(default fallback)
  @allowed_statuses ~w(created completed)

  @primary_key false
  embedded_schema do
    field :correlation_id, :string
    field :amount, :float
    field :processor, :string
    field :requested_at, :string
    field :status, :string
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @permitted_params)
    |> validate_required(@required_fields)
    |> validate_number(:amount, greater_than: 0)
    |> validate_inclusion(:processor, @allowed_processors)
    |> validate_inclusion(:status, @allowed_statuses)
  end
end
