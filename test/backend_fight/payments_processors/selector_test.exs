defmodule BackendFight.PaymentProcessors.SelectorTest do
  use ExUnit.Case

  import Mox

  alias BackendFight.PaymentProcessors.Selector

  setup :verify_on_exit!

  setup do
    default_bypass = Bypass.open(port: 9_001)
    fallback_bypass = Bypass.open(port: 9_002)

    {:ok, default: default_bypass, fallback: fallback_bypass}
  end

  defp expect_redis_cache!(expected_processor) do
    expect(BackendFight.RedisMock, :command!, fn
      :redix, ["SET", "selected_payment_processor", payload, "EX", "5"] ->
        map = Jason.decode!(payload)
        assert map["payment_processor"] == expected_processor
        assert is_binary(map["ts"])
        :ok
    end)
  end

  test "selects default when it's healthy and fast", %{default: d, fallback: f} do
    Bypass.expect_once(d, "GET", "/payments/service-health", fn conn ->
      Plug.Conn.resp(conn, 200, ~s({"failing": false, "minResponseTime": 90}))
    end)

    Bypass.expect_once(f, "GET", "/payments/service-health", fn conn ->
      Plug.Conn.resp(conn, 200, ~s({"failing": false, "minResponseTime": 80}))
    end)

    expect_redis_cache!("default")
    assert :ok = Selector.choose_and_cache_payment_processor()
  end

  test "selects fallback when default is failing and fallback is healthy", %{
    default: d,
    fallback: f
  } do
    Bypass.expect_once(d, "GET", "/payments/service-health", fn conn ->
      Plug.Conn.resp(conn, 200, ~s({"failing": true, "minResponseTime": 10}))
    end)

    Bypass.expect_once(f, "GET", "/payments/service-health", fn conn ->
      Plug.Conn.resp(conn, 200, ~s({"failing": false, "minResponseTime": 80}))
    end)

    expect_redis_cache!("fallback")
    assert :ok = Selector.choose_and_cache_payment_processor()
  end

  test "selects fallback when it's significantly faster", %{default: d, fallback: f} do
    Bypass.expect_once(d, "GET", "/payments/service-health", fn conn ->
      Plug.Conn.resp(conn, 200, ~s({"failing": false, "minResponseTime": 211}))
    end)

    Bypass.expect_once(f, "GET", "/payments/service-health", fn conn ->
      Plug.Conn.resp(conn, 200, ~s({"failing": false, "minResponseTime": 10}))
    end)

    expect_redis_cache!("fallback")
    assert :ok = Selector.choose_and_cache_payment_processor()
  end

  test "falls back to default when both are failing", %{default: d, fallback: f} do
    Bypass.expect_once(d, "GET", "/payments/service-health", fn conn ->
      Plug.Conn.resp(conn, 200, ~s({"failing": true, "minResponseTime": 100}))
    end)

    Bypass.expect_once(f, "GET", "/payments/service-health", fn conn ->
      Plug.Conn.resp(conn, 200, ~s({"failing": true, "minResponseTime": 200}))
    end)

    expect_redis_cache!("default")
    assert :ok = Selector.choose_and_cache_payment_processor()
  end

  test "selects fallback if default request fails but fallback succeeds", %{
    default: d,
    fallback: f
  } do
    Bypass.down(d)

    Bypass.expect_once(f, "GET", "/payments/service-health", fn conn ->
      Plug.Conn.resp(conn, 200, ~s({"failing": false, "minResponseTime": 90}))
    end)

    expect_redis_cache!("fallback")
    assert :ok = Selector.choose_and_cache_payment_processor()
  end

  test "selects default if fallback request fails but default succeeds", %{
    default: d,
    fallback: f
  } do
    Bypass.expect_once(d, "GET", "/payments/service-health", fn conn ->
      Plug.Conn.resp(conn, 200, ~s({"failing": false, "minResponseTime": 50}))
    end)

    Bypass.down(f)

    expect_redis_cache!("default")
    assert :ok = Selector.choose_and_cache_payment_processor()
  end

  describe "current_payment_processor/0" do
    test "returns fallback from cache" do
      payload = Jason.encode!(%{payment_processor: "fallback", ts: DateTime.utc_now()})

      expect(BackendFight.RedisMock, :command, fn :redix, ["GET", "selected_payment_processor"] ->
        {:ok, payload}
      end)

      assert {:ok, "fallback"} = Selector.current_payment_processor()
    end

    test "returns default if cache is missing" do
      expect(BackendFight.RedisMock, :command, fn :redix, ["GET", "selected_payment_processor"] ->
        {:ok, nil}
      end)

      assert {:ok, "default"} = Selector.current_payment_processor()
    end

    test "returns default if cache is invalid" do
      expect(BackendFight.RedisMock, :command, fn :redix, ["GET", "selected_payment_processor"] ->
        {:ok, "invalid-json"}
      end)

      assert {:ok, "default"} = Selector.current_payment_processor()
    end
  end
end
