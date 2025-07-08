defmodule BackendFightWeb.HealthcheckControllerTest do
  use BackendFightWeb.ConnCase, async: true

  import Mox

  alias BackendFight.RedisMock

  setup :verify_on_exit!

  test "returns 200 when Redis and DB are OK", %{conn: conn} do
    expect(RedisMock, :command, fn :redix, ["PING"] -> {:ok, "PONG"} end)

    conn = get(conn, "/healthcheck")

    assert json_response(conn, 200) == %{"status" => "ok"}
  end

  test "returns 500 when Redis fails", %{conn: conn} do
    expect(RedisMock, :command, fn :redix, ["PING"] -> {:error, :econnrefused} end)

    conn = get(conn, "/healthcheck")

    assert json_response(conn, 500) == %{"status" => "error"}
  end
end
