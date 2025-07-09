defmodule BackendFightWeb.ChangesetJSONTest do
  use ExUnit.Case, async: true

  alias BackendFightWeb.ChangesetJSON
  alias Ecto.Changeset

  defmodule Dummy do
    use Ecto.Schema

    embedded_schema do
      field :name, :string
      field :age, :integer
    end

    def changeset(params) do
      %__MODULE__{}
      |> Changeset.cast(params, [:name, :age])
      |> Changeset.validate_required([:name, :age])
      |> Changeset.validate_number(:age, greater_than: 0)
    end
  end

  test "renders validation errors" do
    changeset = Dummy.changeset(%{"age" => -1})

    assert ChangesetJSON.error(%{changeset: changeset}) == %{
             errors: %{
               name: ["can't be blank"],
               age: ["must be greater than 0"]
             }
           }
  end

  test "returns empty errors when changeset is valid" do
    changeset = Dummy.changeset(%{"name" => "Lucas", "age" => 30})

    assert ChangesetJSON.error(%{changeset: changeset}) == %{
             errors: %{}
           }
  end
end
