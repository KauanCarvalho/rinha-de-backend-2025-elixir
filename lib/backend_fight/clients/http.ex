defmodule BackendFight.Clients.HTTP do
  @moduledoc """
  Generic HTTP client using Finch.
  """

  @finch BackendFight.Finch

  def get(url, headers \\ [], opts \\ []) do
    :get
    |> Finch.build(url, headers)
    |> do_request(opts)
  end

  def post(url, body, headers \\ [], opts \\ []) do
    :post
    |> Finch.build(url, headers, body)
    |> do_request(opts)
  end

  defp do_request(request, opts) do
    try do
      case Finch.request(request, @finch, opts) do
        {:ok, %Finch.Response{status: 200, body: body}} ->
          Jason.decode(body)

        {:ok, %Finch.Response{status: status}} ->
          {:error, {:unexpected_status, status}}

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e in RuntimeError ->
        {:error, {:finch_failure, Exception.message(e)}}
    end
  end
end
