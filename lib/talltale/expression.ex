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

  def eval_boolean(expression, binding) when is_binary(expression) do
    eval(expression, binding)
    |> truthy?()
  end

  def truthy?(true), do: true
  def truthy?(number) when is_number(number), do: number > 0
  def truthy?(_), do: false

  defp evalp({:==, _, [x, y]}, binding), do: evalp(x, binding) == evalp(y, binding)
  defp evalp({:!=, _, [x, y]}, binding), do: evalp(x, binding) != evalp(y, binding)
  defp evalp({:<, _, [x, y]}, binding), do: evalp(x, binding) < evalp(y, binding)
  defp evalp({:<=, _, [x, y]}, binding), do: evalp(x, binding) <= evalp(y, binding)
  defp evalp({:>, _, [x, y]}, binding), do: evalp(x, binding) > evalp(y, binding)
  defp evalp({:>=, _, [x, y]}, binding), do: evalp(x, binding) >= evalp(y, binding)
  defp evalp({:in, _, [x, y]}, binding), do: evalp(x, binding) in evalp(y, binding)

  defp evalp({:not, _, [x]}, binding), do: !truthy?(evalp(x, binding))
  defp evalp({:!, _, [x]}, binding), do: !truthy?(evalp(x, binding))

  defp evalp({:&&, _, [x, y]}, binding),
    do: truthy?(evalp(x, binding)) && truthy?(evalp(y, binding))

  defp evalp({:and, _, [x, y]}, binding),
    do: truthy?(evalp(x, binding)) && truthy?(evalp(y, binding))

  defp evalp({:||, _, [x, y]}, binding),
    do: truthy?(evalp(x, binding)) || truthy?(evalp(y, binding))

  defp evalp({:or, _, [x, y]}, binding),
    do: truthy?(evalp(x, binding)) || truthy?(evalp(y, binding))

  defp evalp({:+, _, [x, y]}, binding), do: evalp(x, binding) + evalp(y, binding)
  defp evalp({:-, _, [x, y]}, binding), do: evalp(x, binding) - evalp(y, binding)
  defp evalp({:.., _, [x, y]}, binding), do: evalp(x, binding)..evalp(y, binding)
  defp evalp({var, _, nil}, binding) when is_atom(var), do: Map.get(binding, var, 0)
  defp evalp(literal, _) when is_number(literal), do: literal
end
