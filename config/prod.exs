import Config

# Do not print debug messages in production
config :logger, level: :error

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.

# Configure redis url
config :backend_fight, :redis_url, "redis://localhost:6379"
