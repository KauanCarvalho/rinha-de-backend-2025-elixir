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
  @max_relative_latency_ratio 5
  @max_min_rexponse_time 200
  @cache_ttl 30

  @doc """
  Chooses the most appropriate payment processor (`"default"` or `"fallback"`) based on health and latency,
  and stores the selected value in Redis for quick retrieval.

  ## Selection rules

  - If `default` is healthy and `fallback` is failing → select `"default"`.
  - If `default` is failing and `fallback` is healthy → select `"fallback"`.
  - If both are healthy:
    - Prefer `"default"` **if its latency is at most #{@max_relative_latency_ratio}x the latency of fallback**.
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

    health_data = %{
      current_processor: processor,
      ts: DateTime.utc_now(),
      overwritten: false,
      default: extract_health_info(default_result),
      fallback: extract_health_info(fallback_result)
    }

    cache_health(health_data)
  end

  defp select_processor({:ok, %{failing: false}}, {:ok, %{failing: true}}), do: @default
  defp select_processor({:ok, %{failing: true}}, {:ok, %{failing: false}}), do: @fallback

  defp select_processor({:ok, %{}}, {:error, _}), do: @default
  defp select_processor({:error, _}, {:ok, %{}}), do: @fallback

  defp select_processor(
         {:ok, %{failing: false, min_response_time: d_rt}},
         {:ok, %{failing: false, min_response_time: f_rt}}
       ) do
    if prefer_default?(d_rt, f_rt), do: @default, else: @fallback
  end

  defp select_processor(_, _), do: @default

  defp prefer_default?(d_rt, f_rt) when is_number(d_rt) and is_number(f_rt) do
    d_rt <= @max_min_rexponse_time || d_rt <= f_rt * @max_relative_latency_ratio
  end

  defp prefer_default?(_, _), do: false

  defp extract_health_info({:ok, %{failing: f, min_response_time: r}}),
    do: %{failing: f, min_response_time: r}

  defp extract_health_info(_), do: %{failing: true, min_response_time: nil}

  defp cache_health(data) do
    redis = Application.get_env(:backend_fight, :redis_module, Redix)

    redis.command!(:redix, ["SET", @cache_key, Jason.encode!(data), "EX", "#{@cache_ttl}"])

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
        with {:ok, %{"current_processor" => processor}} <- Jason.decode(json) do
          {:ok, processor}
        else
          _ -> {:ok, @default}
        end

      _ ->
        {:ok, @default}
    end
  end

  @doc """
  Marks a given processor as failing and switches to the alternative processor
  based on the cached health data, without recomputing latencies.

  Only updates the `current_processor` if it matches the failed one.
  """
  def recalculate_payment_processor(failed_processor)
      when failed_processor in [@default, @fallback] do
    redis = Application.get_env(:backend_fight, :redis_module, Redix)

    case redis.command(:redix, ["GET", @cache_key]) do
      {:ok, nil} ->
        :ok

      {:ok, json} ->
        case Jason.decode(json) do
          {:ok, %{"current_processor" => ^failed_processor, "overwritten" => false} = data} ->
            new_processor = other_processor(failed_processor)

            updated_data =
              data
              |> Map.put("current_processor", new_processor)
              |> Map.put("ts", DateTime.utc_now())
              |> Map.put("overwritten", true)

            redis.command!(:redix, [
              "SET",
              @cache_key,
              Jason.encode!(updated_data),
              "EX",
              "#{@cache_ttl}"
            ])

            :ok

          _ ->
            :ok
        end

      _ ->
        :ok
    end
  end

  defp other_processor(@default), do: @fallback
  defp other_processor(@fallback), do: @default
end
