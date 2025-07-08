defmodule BackendFight.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        BackendFightWeb.Telemetry,
        BackendFight.Repo,
        {Redix, {Application.get_env(:backend_fight, :redis_url), name: :redix}},
        {DNSCluster, query: Application.get_env(:backend_fight, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: BackendFight.PubSub},
        # Start a worker by calling: BackendFight.Worker.start_link(arg)
        # {BackendFight.Worker, arg},
        # Start to serve requests, typically the last entry
        BackendFightWeb.Endpoint
      ] ++ scheduler_child()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BackendFight.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BackendFightWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # This function determines whether to start the scheduler based on the application environment
  defp scheduler_child do
    if Application.get_env(:backend_fight, :enable_scheduler?, true) do
      [BackendFight.Scheduler]
    else
      []
    end
  end
end
