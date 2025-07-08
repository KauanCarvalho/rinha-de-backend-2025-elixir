defmodule BackendFight.Crons.PaymentProcessors.HealthcheckManagerTest do
  use ExUnit.Case, async: true

  import Mox
  import ExUnit.CaptureLog

  alias BackendFight.Crons.PaymentProcessors.HealthcheckManager

  setup :verify_on_exit!

  test "logs success when lock is acquired" do
    key = "quantum:healthcheck_manager:lock"

    expect(BackendFight.RedisMock, :command, fn :redix, ["SET", ^key, _, "NX", "EX", _] ->
      {:ok, "OK"}
    end)

    expect(BackendFight.RedisMock, :command, fn :redix, ["EVAL", _lua, "1", ^key, _] ->
      {:ok, 1}
    end)

    log =
      capture_log(fn ->
        assert :ok = HealthcheckManager.run()
      end)

    assert log =~ "[HealthcheckManager] Lock acquired. Health check executed."
  end

  test "logs skip when lock not acquired" do
    key = "quantum:healthcheck_manager:lock"

    expect(BackendFight.RedisMock, :command, fn :redix, ["SET", ^key, _, "NX", "EX", _] ->
      :error
    end)

    log =
      capture_log(fn ->
        assert :ok = HealthcheckManager.run()
      end)

    assert log =~ "[HealthcheckManager] Lock not acquired. Skipping execution."
  end
end
