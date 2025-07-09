defmodule BackendFightWeb.ErrorJSONTest do
  use BackendFightWeb.ConnCase, async: true

  test "renders 404" do
    assert BackendFightWeb.ErrorJSON.render("404.json", %{}) == %{error: "Not found"}
  end

  test "renders 403" do
    assert BackendFightWeb.ErrorJSON.render("403.json", %{}) == %{error: "Forbidden"}
  end

  test "renders 422" do
    assert BackendFightWeb.ErrorJSON.render("422.json", %{message: "Unprocessable Entity"}) ==
             %{error: "Unprocessable Entity"}
  end

  test "renders 500" do
    assert BackendFightWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
