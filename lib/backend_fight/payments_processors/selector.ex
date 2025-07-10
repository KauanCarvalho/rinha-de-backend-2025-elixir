defmodule BackendFight.PaymentProcessors.Selector do
  @moduledoc """
  Responsible for selecting and caching the optimal payment processor (`default` or `fallback`)
  based on health and response time using Redis as a short-lived cache.

  This module periodically queries both processors' health endpoints, compares their statuses and
  latencies, and chooses the most suitable processor. The selection is cached in Redis to avoid
  unnecessary health checks on every request.
  """

  require Logger

  alias BackendFight.Clients.PaymentProcessors.Default.Payments, as: DefaultPayments
  alias BackendFight.Clients.PaymentProcessors.Fallback.Payments, as: FallbackPayments

  @cache_key "selected_payment_processor"
  @default "default"
  @fallback "fallback"
  @default_max_latency_difference 50
  @cache_ttl 5

  @doc """
  Chooses the most appropriate payment processor (`"default"` or `"fallback"`) based on health and latency,
  and stores the selected value in Redis for quick retrieval.

  ## Selection rules

  - If `default` is healthy and `fallback` is failing → select `"default"`.
  - If `default` is failing and `fallback` is healthy → select `"fallback"`.
  - If both are healthy:
    - If `default` is at most #{@default_max_latency_difference}ms slower than `fallback`, select `"default"`.
    - Otherwise, select `"fallback"`.
  - If both fail or data is unavailable, fallback to `"default"`.

  ## Example

      iex> BackendFight.PaymentProcessors.Selector.choose_and_cache_payment_processor()
      :ok
  """
  def choose_and_cache_payment_processor do
    default_result = DefaultPayments.service_health()
    fallback_result = FallbackPayments.service_health()
    processor = select_processor(default_result, fallback_result)

    cache_selection(processor)
  end

  defp select_processor({:ok, %{failing: false}}, {:ok, %{failing: true}}), do: @default
  defp select_processor({:ok, %{failing: true}}, {:ok, %{failing: false}}), do: @fallback

  defp select_processor({:ok, %{}}, {:error, _}), do: @default
  defp select_processor({:error, _}, {:ok, %{}}), do: @fallback

  defp select_processor(
         {:ok, %{failing: false, min_response_time: rt}},
         {:ok, %{failing: false, min_response_time: frt}}
       )
       when rt < frt + @default_max_latency_difference,
       do: @default

  defp select_processor({:ok, %{failing: false}}, {:ok, %{failing: false}}), do: @fallback
  defp select_processor(_, _), do: @default

  defp cache_selection(processor) do
    redis = Application.get_env(:backend_fight, :redis_module, Redix)

    payload = %{
      payment_processor: processor,
      ts: DateTime.utc_now()
    }

    redis.command!(:redix, ["SET", @cache_key, Jason.encode!(payload), "EX", "#{@cache_ttl}"])
    :ok
  end

  @doc """
  Fetches the currently selected payment processor from Redis cache.

  If no processor is cached or decoding fails, defaults to `"default"`.

  ## Example

      iex> BackendFight.PaymentProcessors.Selector.current_payment_processor()
      {:ok, "default"}
  """
  def current_payment_processor do
    redis = Application.get_env(:backend_fight, :redis_module, Redix)

    case redis.command(:redix, ["GET", @cache_key]) do
      {:ok, nil} ->
        {:ok, @default}

      {:ok, json} ->
        with {:ok, %{"payment_processor" => processor}} <- Jason.decode(json) do
          {:ok, processor}
        else
          _ -> {:ok, @default}
        end

      _ ->
        {:ok, @default}
    end
  end
end
