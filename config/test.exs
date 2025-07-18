import Config

# Configure redis url
config :backend_fight, :redis_url, "redis://localhost:6379"

# Configure redis mock
config :backend_fight, :redis_module, BackendFight.RedisMock

# Disable cron jobs in test environment
config :backend_fight, :background_processes?, false

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :backend_fight, BackendFightWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "LmWBEFU2sZ/dTFRdXXXGV+3sgblBrSqtW3+XzJZq7QHrkt51hkm/rQSq++vw8zM/",
  server: false

# Configure the logger to not log during tests
config :logger, backends: []

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Default payment processor configuration
config :backend_fight, :default_payment_processor, base_url: "http://localhost:9001"

# Fallback payment processor configuration
config :backend_fight, :fallback_payment_processor, base_url: "http://localhost:9002"
