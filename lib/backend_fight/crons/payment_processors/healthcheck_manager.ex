defmodule BackendFight.Crons.PaymentProcessors.HealthcheckManager do
  require Logger

  alias BackendFight.DistributedLock
  alias BackendFight.PaymentProcessors.Selector

  @throttle_key "healthcheck:throttle"
  @lock_key "healthcheck:lock"
  @ttl "5"
  @ttl_ms "5100"

  @doc """
  Runs the processor healthcheck with Redis-based throttle and lock:

  - SET NX EX ensures we only *attempt* once every @ttl seconds.
  - If not throttled, tries to acquire lock (to prevent race).
  - Only one node executes per TTL window.
  """
  def run do
    redis = Application.get_env(:backend_fight, :redis_module, Redix)

    case redis.command(:redix, ["SET", @throttle_key, "1", "PX", "#{@ttl_ms}", "NX"]) do
      {:ok, "OK"} ->
        case DistributedLock.with_lock(
               @lock_key,
               fn ->
                 Selector.choose_and_cache_payment_processor()
               end,
               ttl: String.to_integer(@ttl)
             ) do
          :ok ->
            Logger.info("[HealthcheckManager] Healthcheck completed.")

          :lock_not_acquired ->
            Logger.info("[HealthcheckManager] Lock not acquired. Another node may be processing.")
        end

      _ ->
        Logger.info("[HealthcheckManager] Skipping execution: Throttled.")
    end
  end

  @doc """
  Returns the key used for throttling healthcheck execution.
  This key is used to prevent multiple executions within a short time frame.
  """
  def throttle_key, do: @throttle_key

  @doc """
  Returns the key used for locking healthcheck execution.
  This key is used to ensure that only one node can run the healthcheck at a time.
  """
  def lock_key, do: @lock_key
end
