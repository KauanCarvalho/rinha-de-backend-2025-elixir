defmodule BackendFightWeb.Router do
  use BackendFightWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BackendFightWeb do
    get "/healthcheck", HealthcheckController, :index
  end

  scope "/api", BackendFightWeb do
    pipe_through :api
  end
end
