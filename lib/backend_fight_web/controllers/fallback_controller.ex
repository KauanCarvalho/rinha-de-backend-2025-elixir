defmodule BackendFightWeb.FallbackController do
  use BackendFightWeb, :controller

  alias Ecto.Changeset
  alias BackendFightWeb.{ChangesetJSON, ErrorJSON}

  def call(conn, {:error, %Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: ChangesetJSON)
    |> render(:error, changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: ErrorJSON)
    |> render("404.json")
  end

  def call(conn, {:error, :forbidden}) do
    conn
    |> put_status(:forbidden)
    |> put_view(json: ErrorJSON)
    |> render("403.json")
  end

  def call(conn, {:error, reason}) when is_atom(reason) or is_binary(reason) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: ErrorJSON)
    |> render("422.json", message: to_string(reason))
  end
end
