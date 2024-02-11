defmodule Tailmark.Node.List.Data do
  defstruct [
    :type,
    :marker_offset,
    :marker_length,
    bullet_char: nil,
    start: 1,
    delimiter: nil,
    padding: 0
  ]
end
