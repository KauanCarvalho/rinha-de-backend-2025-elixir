defmodule BackendFight.Crons.PaymentProcessors.HealthcheckManager do
  require Logger

  alias BackendFight.DistributedLock

  @lock_key "quantum:healthcheck_manager:lock"
  @lock_ttl 5

  def run do
    case DistributedLock.with_lock(
           @lock_key,
           fn ->
             Process.sleep(1000)
             :ok
           end,
           ttl: @lock_ttl
         ) do
      :lock_not_acquired ->
        Logger.info("[HealthcheckManager] Lock not acquired. Skipping execution.")

      :ok ->
        Logger.info("[HealthcheckManager] Lock acquired. Health check executed.")
    end
  end
end
