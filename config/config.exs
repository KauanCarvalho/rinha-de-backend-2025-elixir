# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :backend_fight,
  ecto_repos: [BackendFight.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :backend_fight, BackendFightWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: BackendFightWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: BackendFight.PubSub

# Cron jobs configuration
config :backend_fight, BackendFight.Scheduler,
  timezone: "Etc/UTC",
  global: true,
  poll_interval: 100,
  jobs: [
    healthcheck_manager: [
      schedule: {:extended, "*/1"},
      task: {BackendFight.Crons.PaymentProcessors.HealthcheckManager, :run, []}
    ]
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure redis module
config :backend_fight, :redis_module, Redix

# Default payment processor configuration
config :backend_fight, :default_payment_processor,
  base_url: System.fetch_env!("PAYMENT_PROCESSOR_DEFAULT_HOST")

# Fallback payment processor configuration
config :backend_fight, :fallback_payment_processor,
  base_url: System.fetch_env!("PAYMENT_PROCESSOR_FALLBACK_HOST")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
