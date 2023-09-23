defmodule IntoArray do
  defstruct [:array, offset: 0, grow: false, raise_on_grow: false]

  def new(array, options \\ []) do
    %__MODULE__{
      array: array,
      offset: Keyword.get(options, :offset, 0),
      grow: Keyword.get(options, :grow, false),
      raise_on_grow: Keyword.get(options, :raise_on_grow, false)
    }
  end

  defimpl Collectable do
    def into(iter) do
      fun = fn
        iter = %@for{
          array: array,
          offset: offset,
          grow: grow,
          raise_on_grow: raise_on_grow
        },
        {:cont, value} ->
          cond do
            offset < Arrays.size(array) ->
              %@for{iter | array: Arrays.replace(array, offset, value), offset: offset + 1}

            grow ->
              %@for{iter | array: Arrays.append(array, value), offset: offset + 1}

            raise_on_grow ->
              raise ArgumentError, "tried writing past the array boundary"

            true ->
              iter
          end

        %@for{array: array}, :done ->
          array

        _, :halt ->
          nil
      end

      {iter, fun}
    end
  end
end
