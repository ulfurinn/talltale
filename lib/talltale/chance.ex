defmodule Talltale.Chance do
  def logistic(x_range, y_start, y_end) do
    k = 1.1 * (x_range.last - x_range.first)
    x0 = (x_range.last - x_range.first) / 2

    fn x ->
      s = 1.0 / (1.0 + :math.exp(-k * (x - x0)))
      p = y_start + (y_end - y_start) * s

      cond do
        p > 1.0 -> 1.0
        p < 0.0 -> 0.0
        true -> p
      end
    end
  end
end
