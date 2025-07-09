defmodule BackendFight.Clients.PaymentProcessors.Default.Payments do
  @moduledoc """
  Client for interacting with the Default Payment Processor API.
  """

  import Ecto.Changeset, only: [apply_changes: 1]

  alias BackendFight.Clients.PaymentProcessors.PaymentParams
  alias BackendFight.Clients.HTTP

  @base_url Application.compile_env!(:backend_fight, :default_payment_processor)[:base_url]
  @service_health_path "payments/service-health"
  @payments_path "payments"
  @timeout 500

  def service_health do
    url = "#{@base_url}/#{@service_health_path}"

    case HTTP.get(url, default_headers(), default_options()) do
      {:ok, %{"failing" => failing, "minResponseTime" => min_response_time}}
      when is_boolean(failing) and is_integer(min_response_time) ->
        {:ok, %{failing: failing, min_response_time: min_response_time}}

      {:ok, other} ->
        {:error, {:unexpected_response, other}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def create(params) when is_map(params) do
    with %Ecto.Changeset{valid?: true} = changeset <- PaymentParams.changeset(params),
         valid_params <- changeset |> apply_changes() |> Map.from_struct(),
         {:ok, json} <- Jason.encode(valid_params),
         url <- "#{@base_url}/#{@payments_path}",
         response <- HTTP.post(url, json, default_headers(), default_options()) do
      case response do
        {:ok, %{"message" => "payment processed successfully"}} = response ->
          response

        {:ok, other} ->
          {:error, {:unexpected_response, other}}

        {:error, reason} ->
          {:error, reason}
      end
    else
      %Ecto.Changeset{valid?: false} = cs ->
        {:error, {:validation_failed, cs}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp default_headers do
    [
      {"content-type", "application/json"},
      {"accept", "application/json"}
    ]
  end

  defp default_options, do: [timeout: @timeout, receive_timeout: @timeout]
end
