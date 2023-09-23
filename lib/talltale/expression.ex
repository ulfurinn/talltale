defmodule Talltale.Expression do
  def eval(expression, binding) when is_binary(expression) do
    expression
    |> Code.string_to_quoted!()
    |> evalp(binding)
  end

  def eval_assign(expression, binding) when is_binary(expression) do
    {:=, _, [{var, _, nil}, value]} =
      expression
      |> Code.string_to_quoted!()

    Map.put(binding, var, max(0, evalp(value, binding)))
  end

  defp evalp({:==, _, [x, y]}, binding), do: evalp(x, binding) == evalp(y, binding)
  defp evalp({:!=, _, [x, y]}, binding), do: evalp(x, binding) != evalp(y, binding)
  defp evalp({:<, _, [x, y]}, binding), do: evalp(x, binding) < evalp(y, binding)
  defp evalp({:<=, _, [x, y]}, binding), do: evalp(x, binding) <= evalp(y, binding)
  defp evalp({:>, _, [x, y]}, binding), do: evalp(x, binding) > evalp(y, binding)
  defp evalp({:>=, _, [x, y]}, binding), do: evalp(x, binding) >= evalp(y, binding)
  defp evalp({:&&, _, [x, y]}, binding), do: evalp(x, binding) && evalp(y, binding)
  defp evalp({:and, _, [x, y]}, binding), do: evalp(x, binding) && evalp(y, binding)
  defp evalp({:||, _, [x, y]}, binding), do: evalp(x, binding) || evalp(y, binding)
  defp evalp({:or, _, [x, y]}, binding), do: evalp(x, binding) || evalp(y, binding)

  defp evalp({:+, _, [x, y]}, binding), do: evalp(x, binding) + evalp(y, binding)
  defp evalp({:-, _, [x, y]}, binding), do: evalp(x, binding) - evalp(y, binding)
  defp evalp({var, _, nil}, binding) when is_atom(var), do: Map.get(binding, var, 0)
  defp evalp(literal, _) when is_number(literal), do: literal
end
