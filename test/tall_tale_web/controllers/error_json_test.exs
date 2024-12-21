defmodule TallTaleWeb.ErrorJSONTest do
  use TallTaleWeb.ConnCase, async: true

  test "renders 404" do
    assert TallTaleWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert TallTaleWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
