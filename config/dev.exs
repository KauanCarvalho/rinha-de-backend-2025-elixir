import Config

# Configure redis url
config :backend_fight, :redis_url, "redis://localhost:6379"

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
port = String.to_integer(System.get_env("PORT") || "4000")

config :backend_fight, BackendFightWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: port],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "oZ8bvE4d020ROejjWDSZZMp8VHFpv+zolqKn5fNwbLT/2dDVoI8SBVD+qvyiCeht",
  watchers: []

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Enable dev routes for dashboard and mailbox
config :backend_fight, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$time] [$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Default payment processor configuration
config :backend_fight, :default_payment_processor, base_url: "http://localhost:8001"

# Fallback payment processor configuration
config :backend_fight, :fallback_payment_processor, base_url: "http://localhost:8002"
