defmodule BackendFight.Processors.PaymentAuthorizer do
  @moduledoc """
  Broadway pipeline that processes created payments using Redis-based queue,
  sends them to the processor (default or fallback), and stores final result
  in Redis hash 'payments'. Requeues on failure.
  """

  use Broadway

  alias Broadway.Message
  alias BackendFight.Clients.PaymentProcessors.Default.Payments, as: DefaultProcessor
  alias BackendFight.Clients.PaymentProcessors.Fallback.Payments, as: FallbackProcessor
  alias BackendFight.PaymentProcessors.Selector
  alias BackendFight.Producers.Enqueuer

  require Logger

  @redis_key_result "payments"
  @redis_key_queue "payments_created"

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {Enqueuer, []},
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 300,
          max_demand: 5
        ]
      ]
    )
  end

  @impl true
  def handle_message(
        _processor,
        %Message{data: %{"correlationId" => cid, "amount" => amount} = payload} = message,
        _ctx
      ) do
    with {:ok, processor} <- Selector.current_payment_processor(),
         {:ok, processor_module} <- choose_processor(processor),
         ts <- DateTime.utc_now() |> DateTime.truncate(:millisecond) |> DateTime.to_iso8601(),
         params <- %{
           correlationId: cid,
           amount: amount,
           requestedAt: ts
         },
         {:ok, _} <- processor_module.create(params) do
      persist_result(cid, amount, processor, ts)
    else
      _ ->
        requeue_message(Jason.encode!(payload))
    end

    message
  end

  defp choose_processor("default"), do: {:ok, DefaultProcessor}
  defp choose_processor("fallback"), do: {:ok, FallbackProcessor}
  defp choose_processor(_), do: {:error, :invalid_processor}

  defp persist_result(correlation_id, amount, processor, requested_at) do
    data = %{
      correlationId: correlation_id,
      amount: amount,
      processor: processor,
      createdAt: requested_at
    }

    Redix.command(:redix, [
      "HSET",
      @redis_key_result,
      correlation_id,
      Jason.encode!(data)
    ])
  end

  defp requeue_message(payload_json) do
    Redix.command(:redix, [
      "LPUSH",
      @redis_key_queue,
      payload_json
    ])
  end
end
