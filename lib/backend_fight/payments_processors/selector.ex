defmodule BackendFight.PaymentProcessors.Selector do
  @moduledoc """
  Selects and caches the best available payment processor using Redis.
  """

  alias BackendFight.Clients.PaymentProcessors.Default.Payments, as: DefaultPayments
  alias BackendFight.Clients.PaymentProcessors.Fallback.Payments, as: FallbackPayments

  @default_min_response_time 100
  @cache_key "selected_payment_processor"
  @default "default"
  @fallback "fallback"
  @fallback_multiplier 5
  @cache_ttl 10

  @doc """
  Chooses the most appropriate payment processor between `default` and `fallback`
  based on health and latency. Caches the selected processor in Redis.

  ### Selection rules:

  - If default is healthy and fast (< #{@default_min_response_time}ms), it is selected immediately.
  - If default is failing and fallback is healthy, fallback is selected.
  - If both are healthy, but fallback is significantly faster (5x or more), fallback is selected.
  - In all other cases, default is selected.

  ## Examples

      iex> BackendFight.PaymentProcessors.Selector.choose_and_cache_payment_processor()
      :ok
  """
  def choose_and_cache_payment_processor do
    default_result = DefaultPayments.service_health()
    fallback_result = FallbackPayments.service_health()
    processor = select_processor(default_result, fallback_result)

    cache_selection(processor)
  end

  defp select_processor({:ok, %{failing: false, min_response_time: rt}}, _fallback)
       when rt < @default_min_response_time,
       do: @default

  defp select_processor({:ok, %{failing: true}}, {:ok, %{failing: false}}), do: @fallback

  defp select_processor(
         {:ok, %{failing: false, min_response_time: rt}},
         {:ok, %{failing: false, min_response_time: frt}}
       )
       when frt < rt * @fallback_multiplier,
       do: @fallback

  defp select_processor({:error, _}, {:ok, %{failing: false}}), do: @fallback

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
  Returns the currently selected payment processor from Redis cache.

  If no selection is cached or an error occurs, it defaults to `"default"`.

  ## Examples

      iex> Selector.current_payment_processor()
      {:ok, "default"}

      iex> Selector.current_payment_processor()
      {:ok, "fallback"}
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
