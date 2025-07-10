defmodule BackendFightWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the web layer.

  It provides a default connection for use in tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint BackendFightWeb.Endpoint

      import Plug.Conn
      import Phoenix.ConnTest
      import BackendFightWeb.ConnCase
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
