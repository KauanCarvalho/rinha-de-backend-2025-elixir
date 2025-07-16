defmodule BackendFight.Producers.Enqueuer do
  @moduledoc """
  GenStage producer that polls Redis for enqueued payments
  and emits Broadway.Messages with `Broadway.NoopAcknowledger`.
  """

  use GenStage
  alias Broadway.Message

  require Logger

  @poll_interval 10
  @queue_key "payments_created"
  @redix :redix

  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:producer, %{demand: 0}}
  end

  @impl true
  def handle_demand(incoming_demand, %{demand: existing_demand} = state) do
    Process.send(self(), :poll, [])
    {:noreply, [], %{state | demand: existing_demand + incoming_demand}}
  end

  @impl true
  def handle_info(:poll, %{demand: demand} = state) when demand > 0 do
    messages = fetch_from_redis(demand)

    next_state = %{state | demand: max(demand - length(messages), 0)}

    if messages == [] do
      Process.send_after(self(), :poll, @poll_interval)
    else
      Process.send(self(), :poll, [])
    end

    {:noreply, messages, next_state}
  end

  def handle_info(:poll, state) do
    Process.send_after(self(), :poll, @poll_interval)
    {:noreply, [], state}
  end

  defp fetch_from_redis(count) do
    Enum.map(1..count, fn _ ->
      case Redix.command(@redix, ["RPOP", @queue_key]) do
        {:ok, nil} ->
          nil

        {:ok, json} ->
          case Jason.decode(json) do
            {:ok, data} ->
              %Message{
                data: data,
                acknowledger: {Broadway.NoopAcknowledger, nil, nil}
              }

            _ ->
              nil
          end

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end
end
