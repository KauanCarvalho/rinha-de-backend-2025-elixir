defmodule BackendFight.Crons.PaymentProcessors.HealthcheckManagerTest do
  use ExUnit.Case, async: false

  import Mox
  import ExUnit.CaptureLog

  alias BackendFight.Crons.PaymentProcessors.HealthcheckManager

  setup :verify_on_exit!

  @throttle_key HealthcheckManager.throttle_key()
  @lock_key HealthcheckManager.lock_key()

  describe "run/0" do
    test "skips execution when throttled" do
      expect(BackendFight.RedisMock, :command, fn
        :redix, ["SET", @throttle_key, "1", "EX", _, "NX"] ->
          {:error, :already_set}
      end)

      log =
        capture_log(fn ->
          assert HealthcheckManager.run() == :ok
        end)

      assert log =~ "[HealthcheckManager] Skipping execution: Throttled."
    end

    test "runs healthcheck end-to-end when not throttled and lock is acquired" do
      bypass_default = Bypass.open(port: 9_001)
      bypass_fallback = Bypass.open(port: 9_002)

      Bypass.expect_once(bypass_default, "GET", "/payments/service-health", fn conn ->
        Plug.Conn.resp(conn, 200, ~s({"failing": false, "minResponseTime": 100}))
      end)

      Bypass.expect_once(bypass_fallback, "GET", "/payments/service-health", fn conn ->
        Plug.Conn.resp(conn, 200, ~s({"failing": false, "minResponseTime": 90}))
      end)

      expect(BackendFight.RedisMock, :command, 3, fn
        :redix, ["SET", @throttle_key, "1", "EX", _, "NX"] ->
          {:ok, "OK"}

        :redix, ["SET", @lock_key, _, "NX", "EX", _] ->
          {:ok, "OK"}

        :redix, ["EVAL", _, "1", @lock_key, _] ->
          {:ok, 1}
      end)

      expect(BackendFight.RedisMock, :command!, fn
        :redix, ["SET", "selected_payment_processor", payload, "EX", "10"] ->
          assert %{"payment_processor" => "fallback", "ts" => _ts} = Jason.decode!(payload)
          {:ok, "OK"}
      end)

      log =
        capture_log(fn ->
          assert HealthcheckManager.run() == :ok
        end)

      assert log =~ "[HealthcheckManager] Lock acquired. Running healthcheck."
      assert log =~ "[HealthcheckManager] Healthcheck completed."
    end
  end

  describe "throttle_key/0" do
    test "returns the correct throttle key" do
      assert is_binary(@lock_key) and @lock_key != ""
    end
  end

  describe "lock_key/0" do
    test "returns the correct lock key" do
      assert is_binary(@lock_key) and @lock_key != ""
    end
  end
end
