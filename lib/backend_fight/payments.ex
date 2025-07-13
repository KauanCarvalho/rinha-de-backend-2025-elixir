defmodule BackendFight.Payments do
  @moduledoc """
  The `BackendFight.Payments` module is responsible for handling payment-related operations,
  including enqueuing new payment requests to Redis, purging the Redis database, and generating
  summaries of processed payments.

  It does not persist data in a traditional database — all operations are in-memory via Redis.
  """

  import Ecto.Query, warn: false

  alias Ecto.UUID

  @queue_key "payments_created"

  @doc """
  Validates and enqueues a payment request into the Redis list `"payments_created"`.

  ## Parameters

    - `%{"correlationId" => id, "amount" => amount}`: Map with a valid UUID string and a numeric or string amount.

  ## Returns

    - `{:ok, :enqueued}` on success
    - `{:error, :invalid_correlation_id}` if the UUID is invalid
    - `{:error, :invalid_payload}` if input is malformed or missing required fields

  The enqueued payment is serialized as a JSON object with the following structure:

    - `correlationId`: string UUID
    - `amount`: float
    - `requestedAt`: ISO8601 UTC timestamp (truncated to milliseconds)
  """
  def enqueue_payment(%{"correlationId" => correlation_id, "amount" => amount})
      when is_binary(correlation_id) and (is_number(amount) or is_binary(amount)) do
    with {:ok, uuid} <- UUID.cast(correlation_id),
         {:ok, json} <-
           Jason.encode(%{
             correlationId: uuid,
             amount: normalize_amount(amount)
           }),
         {:ok, _} <- redis().command(:redix, ["LPUSH", @queue_key, json]) do
      {:ok, :enqueued}
    else
      :error -> {:error, :invalid_correlation_id}
      {:error, _} = err -> err
    end
  end

  def enqueue_payment(_), do: {:error, :invalid_payload}

  defp normalize_amount(amount) when is_binary(amount), do: String.to_float(amount)
  defp normalize_amount(amount), do: amount

  @doc """
  Purges all keys from the current Redis database (equivalent to `FLUSHDB`).

  ## Returns

    - `{:ok, "OK"}` on success
    - `{:error, reason}` on failure
  """
  def purge_redis do
    redis().command(:redix, ["FLUSHDB"])
  end

  @doc """
  Returns a summary of all payments stored in the Redis hash `"payments"` grouped by processor.

  Each hash entry must be a JSON-encoded map with:

    - `correlationId`: string
    - `amount`: float
    - `processor`: `"default"` or `"fallback"`
    - `createdAt`: ISO8601 UTC string

  ## Parameters

    - `params`: optional map with keys `"from"` and/or `"to"` (ISO8601 UTC strings)

  If `"from"` and/or `"to"` are provided, the summary includes only payments within that range.

  ## Example Return

  ```elixir
    %{
      "default" => %{totalRequests: 123, totalAmount: 4567.89},
      "fallback" => %{totalRequests: 45, totalAmount: 789.10}
    }
  """
  def get_summary(params \\ %{}) do
    {:ok, entries} = redis().command(:redix, ["HGETALL", "payments"])

    from_dt = parse_datetime(Map.get(params, "from"))
    to_dt = parse_datetime(Map.get(params, "to"))

    entries
    |> Enum.chunk_every(2)
    |> Stream.map(fn [_key, json] -> Jason.decode(json) end)
    |> Stream.filter(&match?({:ok, _}, &1))
    |> Stream.map(fn {:ok, data} -> data end)
    |> maybe_filter_by_date_stream(from_dt, to_dt)
    |> Enum.reduce(
      %{
        "default" => %{totalRequests: 0, totalAmount: 0.0},
        "fallback" => %{totalRequests: 0, totalAmount: 0.0}
      },
      fn %{"processor" => processor, "amount" => amount}, acc ->
        if Map.has_key?(acc, processor) do
          update_in(acc[processor], fn val ->
            %{
              totalRequests: val.totalRequests + 1,
              totalAmount: val.totalAmount + amount
            }
          end)
        else
          acc
        end
      end
    )
    |> round_totals()
  end

  defp maybe_filter_by_date_stream(stream, nil, nil), do: stream

  defp maybe_filter_by_date_stream(stream, from, to) do
    Stream.filter(stream, fn %{"createdAt" => ts} ->
      case DateTime.from_iso8601(ts) do
        {:ok, dt, _} ->
          cond do
            from && to -> DateTime.compare(dt, from) != :lt and DateTime.compare(dt, to) != :gt
            from -> DateTime.compare(dt, from) != :lt
            to -> DateTime.compare(dt, to) != :gt
            true -> true
          end

        _ ->
          false
      end
    end)
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(ts) do
    case DateTime.from_iso8601(ts) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp round_totals(summary) do
    Map.new(summary, fn {k, v} ->
      {k,
       %{
         totalRequests: v.totalRequests,
         totalAmount: Float.round(v.totalAmount, 2)
       }}
    end)
  end

  defp redis, do: Application.get_env(:backend_fight, :redis_module, Redix)
end
