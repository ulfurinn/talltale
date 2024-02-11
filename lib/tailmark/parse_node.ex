defprotocol Tailmark.ParseNode do
  def start(node, state, container)
  def can_contain?(node, module)
  def continue(node, state)
  def finalize(node, state)
end
