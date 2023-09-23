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

    value =
      case evalp(value, binding) do
        int when is_integer(int) -> max(0, int)
        f when is_float(f) -> max(0, round(f))
      end

    Map.put(binding, var, value)
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
  defp evalp({:*, _, [x, y]}, binding), do: evalp(x, binding) * evalp(y, binding)
  defp evalp({:/, _, [x, y]}, binding), do: evalp(x, binding) / evalp(y, binding)
  defp evalp({:**, _, [x, y]}, binding), do: evalp(x, binding) ** evalp(y, binding)
  defp evalp({:div, _, [x, y]}, binding), do: div(evalp(x, binding), evalp(y, binding))
  defp evalp({:mod, _, [x, y]}, binding), do: rem(evalp(x, binding), evalp(y, binding))
  defp evalp({:rem, _, [x, y]}, binding), do: rem(evalp(x, binding), evalp(y, binding))
  defp evalp({:.., _, [x, y]}, binding), do: evalp(x, binding)..evalp(y, binding)

  defp evalp({var, _, nil}, binding) when is_atom(var), do: Map.get(binding, var, 0)
  defp evalp(literal, _) when is_number(literal), do: literal

  defp evalp({:if, _, [x, a, b]}, binding) do
    if truthy?(evalp(x, binding)) do
      evalp(a, binding)
    else
      evalp(b, binding)
    end
  end
end
