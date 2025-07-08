defmodule BackendFight.Clients.PaymentProcessors.Fallback.Payments do
  @moduledoc """
  Client for interacting with the Fallback Payment Processor API.
  """

  alias BackendFight.Clients.HTTP

  @base_url Application.compile_env!(:backend_fight, :fallback_payment_processor)[:base_url]
  @service_health_path "payments/service-health"
  @timeout 500

  def service_health do
    url = "#{@base_url}/#{@service_health_path}"

    case HTTP.get(url, [], default_options()) do
      {:ok, %{"failing" => failing, "minResponseTime" => min_response_time}}
      when is_boolean(failing) and is_integer(min_response_time) ->
        {:ok, %{failing: failing, min_response_time: min_response_time}}

      {:ok, other} ->
        {:error, {:unexpected_response, other}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp default_options, do: [timeout: @timeout, receive_timeout: @timeout]
end
