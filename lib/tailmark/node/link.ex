defmodule Tailmark.Node.Link do
  defstruct [:ref, :parent, :destination, :title, :embed?, children: []]

  def new(destination, title, embed?) do
    %__MODULE__{ref: make_ref(), destination: destination, title: title, embed?: embed?}
  end

  defimpl Inspect do
    def inspect(%{destination: destination, embed?: false}, _) do
      "Link => #{destination}"
    end

    def inspect(%{destination: destination, embed?: true}, _) do
      "Embed => #{destination}"
    end
  end
end
