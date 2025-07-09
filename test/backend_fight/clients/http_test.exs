defmodule BackendFight.Clients.HTTPTest do
  use ExUnit.Case, async: true

  alias BackendFight.Clients.HTTP
  alias Mint.TransportError

  setup do
    {:ok, bypass: Bypass.open()}
  end

  describe "GET requests" do
    test "returns decoded JSON for 200 OK", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/test", fn conn ->
        Plug.Conn.resp(conn, 200, ~s({"ok": true}))
      end)

      url = "http://localhost:#{bypass.port}/test"
      assert {:ok, %{"ok" => true}} = HTTP.get(url)
    end

    test "returns error for non-200 response", %{bypass: bypass} do
      Bypass.expect_once(bypass, "GET", "/notfound", fn conn ->
        Plug.Conn.resp(conn, 404, "Not Found")
      end)

      url = "http://localhost:#{bypass.port}/notfound"
      assert {:error, {:unexpected_status, 404}} = HTTP.get(url)
    end

    test "returns error for request failure" do
      bypass = Bypass.open()
      Bypass.down(bypass)

      url = "http://localhost:#{bypass.port}/fail"
      assert {:error, %TransportError{reason: :econnrefused}} = HTTP.get(url)
    end
  end

  describe "POST requests" do
    test "returns decoded JSON for 200 OK", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/create", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert body == ~s({"name":"test"})

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, ~s({"created": true}))
      end)

      url = "http://localhost:#{bypass.port}/create"
      headers = [{"content-type", "application/json"}]
      body = ~s({"name":"test"})

      assert {:ok, %{"created" => true}} = HTTP.post(url, body, headers)
    end

    test "returns error for non-200 response", %{bypass: bypass} do
      Bypass.expect_once(bypass, "POST", "/fail", fn conn ->
        Plug.Conn.resp(conn, 500, "Internal Server Error")
      end)

      url = "http://localhost:#{bypass.port}/fail"
      body = ~s({})
      headers = [{"content-type", "application/json"}]

      assert {:error, {:unexpected_status, 500}} = HTTP.post(url, body, headers)
    end
  end
end
