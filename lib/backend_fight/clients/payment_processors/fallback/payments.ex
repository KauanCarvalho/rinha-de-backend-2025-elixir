defmodule BackendFight.Clients.PaymentProcessors.Fallback.Payments do
  @moduledoc """
  Client module for interacting with the Fallback Payment Processor API.

  This module provides functions to:
  - Check the health status of the payment processor service.
  - Send a payment request using validated parameters.

  All requests use a base URL configured via the `:fallback_payment_processor` key in `:backend_fight` config.
  """

  import Ecto.Changeset, only: [apply_changes: 1]

  alias BackendFight.Clients.PaymentProcessors.PaymentParams
  alias BackendFight.Clients.HTTP
  alias Ecto.Changeset

  @service_health_path "payments/service-health"
  @payments_path "payments"
  @timeout 5_000

  @doc """
  Performs a health check on the fallback payment processor service.

  ## Returns
    - `{:ok, %{failing: boolean(), min_response_time: integer()}}` if the service responds with a valid status.
    - `{:error, {:unexpected_response, map()}}` if the response structure is invalid.
    - `{:error, term()}` if the request fails.

  ## Examples

      iex> service_health()
      {:ok, %{failing: false, min_response_time: 34}}
  """
  def service_health do
    url = "#{base_url()}/#{@service_health_path}"

    case HTTP.get(url, fallback_headers(), fallback_options()) do
      {:ok, %{"failing" => failing, "minResponseTime" => min_response_time}}
      when is_boolean(failing) and is_integer(min_response_time) ->
        {:ok, %{failing: failing, min_response_time: min_response_time}}

      {:ok, other} ->
        {:error, {:unexpected_response, other}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Sends a payment creation request to the fallback payment processor.

  The `params` map will be validated using a changeset, and only valid data will be sent.

  ## Parameters
    - `params` (`map()`): Payment parameters including `correlationId`, `amount`, and `requestedAt`.

  ## Returns
    - `{:ok, map()}` if the payment was processed successfully.
    - `{:error, {:validation_failed, Ecto.Changeset.t()}}` if validation fails.
    - `{:error, {:unexpected_response, map()}}` if the API responds with an unexpected payload.
    - `{:error, term()}` for other errors.

  ## Examples

      iex> create(%{"correlationId" => "abc-123", "amount" => 100.0, "requestedAt" => "2025-07-10T12:00:00Z"})
      {:ok, %{"message" => "payment processed successfully"}}
  """
  def create(params) when is_map(params) do
    with %Changeset{valid?: true} = changeset <- PaymentParams.changeset(params),
         valid_params <- changeset |> apply_changes() |> Map.from_struct(),
         {:ok, json} <- Jason.encode(valid_params) do
      url = "#{base_url()}/#{@payments_path}"

      case HTTP.post(url, json, fallback_headers(), fallback_options()) do
        {:ok, %{"message" => "payment processed successfully"}} = response ->
          response

        {:ok, other} ->
          {:error, {:unexpected_response, other}}

        {:error, reason} ->
          {:error, reason}
      end
    else
      %Changeset{valid?: false} = cs ->
        {:error, {:validation_failed, cs}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fallback_headers do
    [
      {"content-type", "application/json"},
      {"accept", "application/json"}
    ]
  end

  defp fallback_options, do: [timeout: @timeout, receive_timeout: @timeout]

  defp base_url, do: Application.get_env(:backend_fight, :fallback_payment_processor)[:base_url]
end
