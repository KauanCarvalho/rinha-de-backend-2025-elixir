defmodule BackendFightWeb.ChangesetJSON do
  @moduledoc """
  JSON view used by the FallbackController to render validation errors from changesets.
  """

  @doc """
  Translates a changeset into a map of user-friendly error messages.

  ## Example

      iex> ChangesetJSON.error(%{changeset: some_changeset})
      %{errors: %{field: ["can't be blank"]}}

  """
  def error(%{changeset: changeset}) do
    %{errors: translate_errors(changeset)}
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {k, v}, acc -> String.replace(acc, "%{#{k}}", to_string(v)) end)
    end)
  end
end
