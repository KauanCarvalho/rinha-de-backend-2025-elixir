defmodule BackendFightWeb.Router do
  use BackendFightWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BackendFightWeb do
    get "/healthcheck", HealthcheckController, :index
  end

  scope "/", BackendFightWeb do
    pipe_through :api

    post "/payments", PaymentController, :create
    post "/purge-payments", PaymentController, :purge
    get "/payments-summary", PaymentController, :summary
  end
end
