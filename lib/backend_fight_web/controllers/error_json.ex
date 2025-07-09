defmodule BackendFightWeb.ErrorJSON do
  @moduledoc """
  Handles JSON errors rendered by the FallbackController.
  """

  def render("404.json", _), do: %{error: "Not found"}
  def render("403.json", _), do: %{error: "Forbidden"}
  def render("422.json", %{message: message}), do: %{error: message}

  def render(template, _assigns),
    do: %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
end
