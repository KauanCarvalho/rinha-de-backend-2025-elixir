defmodule BackendFight.Repo.Migrations.CreatePayments do
  use Ecto.Migration

  def change do
    create table(:payments, primary_key: false) do
      add :correlation_id, :uuid, primary_key: true
      add :amount, :decimal, precision: 18, scale: 2, null: false
      add :processor, :string, null: true
      add :requested_at, :utc_datetime_usec, null: false
      add :status, :string, null: false
    end

    create index(:payments, [:requested_at])
    create index(:payments, [:status])
  end
end
