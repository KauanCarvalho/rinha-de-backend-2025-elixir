defmodule BackendFightWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers and routers for the BackendFight API.

  This can be used in your application as:

      use BackendFightWeb, :controller
      use BackendFightWeb, :router
  """

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:json]

      import Plug.Conn
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
