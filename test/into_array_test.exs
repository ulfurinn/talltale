defmodule IntoArrayTest do
  use ExUnit.Case

  test "writes with zero offset" do
    initial = Arrays.empty(size: 5)
    modified = [1, 2, 3] |> Enum.into(IntoArray.new(initial))
    assert [1, 2, 3, nil, nil] = Arrays.to_list(modified)
  end

  test "writes with non-zero offset" do
    initial = Arrays.empty(size: 5)
    modified = [1, 2, 3] |> Enum.into(IntoArray.new(initial, offset: 1))
    assert [nil, 1, 2, 3, nil] = Arrays.to_list(modified)
  end

  test "without grow, ignores writes past the boundary" do
    initial = Arrays.empty(size: 5)
    modified = [1, 2, 3] |> Enum.into(IntoArray.new(initial, offset: 3))
    assert [nil, nil, nil, 1, 2] = Arrays.to_list(modified)
  end

  test "with grow, writes past the boundary" do
    initial = Arrays.empty(size: 5)
    modified = [1, 2, 3] |> Enum.into(IntoArray.new(initial, offset: 3, grow: true))
    assert [nil, nil, nil, 1, 2, 3] = Arrays.to_list(modified)
  end

  test "with raise_on_grow, raises on trying to write past the boundary" do
    initial = Arrays.empty(size: 5)

    assert_raise ArgumentError, fn ->
      [1, 2, 3] |> Enum.into(IntoArray.new(initial, offset: 3, raise_on_grow: true))
    end
  end
end
