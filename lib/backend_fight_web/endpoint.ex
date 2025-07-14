defmodule BackendFightWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :backend_fight

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug BackendFightWeb.Router
end
