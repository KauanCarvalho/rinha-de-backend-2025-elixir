defmodule BackendFight.Producers.Enqueuer do
  @moduledoc """
  GenStage producer that polls Redis for enqueued payments
  and emits Broadway.Messages with `Broadway.NoopAcknowledger`.
  """

  use GenStage

  alias Broadway.{Message, NoopAcknowledger}

  require Logger

  @poll_interval 5
  @queue_key "payments_created"
  @redix :redix

  @rpop_script """
  local key = KEYS[1]
  local n = tonumber(ARGV[1])
  local res = {}
  for i = 1, n do
    local val = redis.call("RPOP", key)
    if not val then break end
    table.insert(res, val)
  end
  return res
  """

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
    case Redix.command(@redix, ["EVAL", @rpop_script, "1", @queue_key, "#{count}"]) do
      {:ok, items} when is_list(items) ->
        for json <- items,
            {:ok, data} <- [Jason.decode(json)] do
          %Message{data: data, acknowledger: {NoopAcknowledger, nil, nil}}
        end

      _ ->
        []
    end
  end
end
