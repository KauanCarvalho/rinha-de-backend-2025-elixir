defmodule BackendFight.Payments do
  alias BackendFight.Repo
  alias BackendFight.Schemas.Payment
  alias Ecto.UUID

  def create_payment(%{"correlationId" => correlation_id, "amount" => amount})
      when is_binary(correlation_id) and is_number(amount) do
    with {:ok, uuid} <- UUID.cast(correlation_id) do
      requested_at = DateTime.utc_now()

      %Payment{}
      |> Payment.changeset(%{
        correlation_id: uuid,
        amount: Decimal.new("#{amount}"),
        processor: :default,
        requested_at: requested_at,
        status: :created
      })
      |> Repo.insert()
    else
      :error ->
        {:error, :invalid_correlation_id}
    end
  end

  def create_payment(_), do: {:error, :invalid_payload}
end
