defmodule Tailmark.Doctree do
  defstruct [:root, :nodes]

  def new(root) do
    %__MODULE__{
      root: root.ref,
      nodes: %{root.ref => root}
    }
  end

  def print(%__MODULE__{root: root, nodes: nodes}) do
    print(root, nodes, 0)
  end

  defp print(node, nodes, indent) do
    node = nodes[node]

    IO.write(String.duplicate(" ", indent))
    IO.write(inspect(node))
    IO.puts("")

    case node do
      %{children: children} ->
        children |> Enum.each(&print(&1, nodes, indent + 1))

      _ ->
        nil
    end
  end

  def get_node(_, nil), do: nil

  def get_node(%__MODULE__{nodes: nodes}, ref) when is_reference(ref) do
    nodes[ref]
  end

  def put_node(tree = %__MODULE__{nodes: nodes}, node) do
    %__MODULE__{tree | nodes: Map.put(nodes, node.ref, node)}
  end

  def append_child(tree, parent, children) when is_list(children) do
    Enum.reduce(children, tree, &append_child(&2, parent, &1))
  end

  def append_child(tree, parent_ref, child) when is_reference(parent_ref) do
    child = if is_reference(child), do: get_node(tree, child), else: child
    child = %{child | parent: parent_ref}
    parent = get_node(tree, parent_ref)
    parent = %{parent | children: parent.children ++ [child.ref]}

    tree
    |> put_node(parent)
    |> put_node(child)
  end

  def insert_after(tree, sibling, node) when is_reference(sibling) do
    sibling = get_node(tree, sibling)
    node = %{node | parent: sibling.parent}
    parent = get_node(tree, sibling.parent)
    parent = %{parent | children: insert_after1(parent.children, sibling.ref, node.ref)}

    tree
    |> put_node(parent)
    |> put_node(node)
  end

  defp insert_after1(refs, ref, new_ref)
  defp insert_after1([ref | refs], ref, new_ref), do: [ref, new_ref | refs]
  defp insert_after1([h | refs], ref, new_ref), do: [h | insert_after1(refs, ref, new_ref)]

  def cut_range(tree = %__MODULE__{}, from, to) do
    from = get_node(tree, from)
    to = get_node(tree, to)

    if from.parent != to.parent do
      raise "Cannot cut range from different parents"
    end

    parent = get_node(tree, from.parent)
    {cut, remaining} = cut_range1(parent.children, from.ref, to.ref)
    parent = %{parent | children: remaining}
    tree = put_node(tree, parent)
    {tree, cut}
  end

  defp cut_range1(refs, from, to) do
    {before_from, [from | after_from]} = Enum.split_while(refs, &(&1 != from))
    {between, tail} = Enum.split_while(after_from, &(&1 != to))
    {between, before_from ++ [from | tail]}
  end

  def cut_from(tree = %__MODULE__{}, to) when is_reference(to) do
    to = get_node(tree, to)
    parent = get_node(tree, to.parent)
    {remaining, cut} = Enum.split_while(parent.children, &(&1 != to.ref))
    parent = %{parent | children: remaining}
    tree = put_node(tree, parent)
    {tree, cut}
  end

  def next_sibling(tree = %__MODULE__{nodes: nodes}, ref) when is_reference(ref) do
    node = nodes[ref]
    parent = nodes[node.parent]
    children = parent.children
    get_node(tree, next_ref(children, ref))
  end

  def remove_node(tree = %__MODULE__{}, node) do
    node = if is_reference(node), do: get_node(tree, node), else: node
    parent = get_node(tree, node.parent)
    parent = %{parent | children: List.delete(parent.children, node.ref)}
    tree = put_node(tree, parent)
    %{tree | nodes: Map.delete(tree.nodes, node.ref)}
  end

  def flatten_refs(%__MODULE__{root: root, nodes: nodes}) do
    flatten_refs(root, nodes)
  end

  def flatten_refs(node = %{children: children}, nodes) do
    %{node | children: children |> Enum.map(&flatten_refs(&1, nodes))}
  end

  def flatten_refs(node, nodes) when is_reference(node) do
    nodes[node] |> flatten_refs(nodes)
  end

  def flatten_refs(node, _), do: node

  defp next_ref(refs, ref)
  defp next_ref([ref, next | _], ref), do: next
  defp next_ref([_ | refs], ref), do: next_ref(refs, ref)
  defp next_ref([], _), do: nil
end
