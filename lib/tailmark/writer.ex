defmodule Tailmark.Writer do
  alias Tailmark.Document
  alias Tailmark.Node

  def to_html(string) when is_binary(string) do
    string
    |> String.replace("\"", "&quot;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  def to_html(%Document{children: nodes}) do
    nodes
    |> to_html()
    |> List.flatten()
    |> dedup_newlines()
    |> strip_leading_newline()
  end

  def to_html(nodes) when is_list(nodes), do: nodes |> Enum.map(&to_html/1)

  def to_html(%Node.Text{content: content}), do: to_html(content)
  def to_html(%Node.Linebreak{hard: true}), do: ["<br />", "\n"]
  def to_html(%Node.Linebreak{hard: false}), do: ["\n"]

  def to_html(%Node.Heading.ATX{level: level, children: children}) do
    ["\n", "<h#{level}>", to_html(children), "</h#{level}>", "\n"]
  end

  def to_html(%Node.Heading.Setext{level: level, children: children}) do
    ["\n", "<h#{level}>", to_html(children), "</h#{level}>", "\n"]
  end

  def to_html(%Node.Code.Fenced{content: content, info: nil}) do
    ["\n", "<pre><code>", content, "</code></pre>", "\n"]
  end

  def to_html(%Node.Code.Fenced{content: content, info: info}) do
    language = info |> String.split(" ") |> List.first()
    ["\n", "<pre><code class=\"language-", language, "\">", content, "</code></pre>", "\n"]
  end

  def to_html(%Node.Code.Indented{content: content}) do
    ["\n", "<pre><code>", content, "</code></pre>", "\n"]
  end

  def to_html(%Node.Code.Inline{content: content}) do
    ["<code>", content, "</code>"]
  end

  def to_html(%Node.Link{destination: destination, title: title, children: children, embed?: true}) do
    alt = children |> to_text()

    [
      "<img src=\"",
      destination,
      "\"",
      if(alt != "", do: [" alt=\"", alt, "\""], else: []),
      if(title, do: [" title=\"", title, "\""], else: []),
      " />"
    ]
  end

  def to_html(%Node.Link{
        destination: destination,
        title: nil,
        children: children,
        embed?: false
      }) do
    ["<a href=\"", destination, "\">", to_html(children), "</a>"]
  end

  def to_html(%Node.Link{
        destination: destination,
        title: title,
        children: children,
        embed?: false
      }) do
    ["<a href=\"", destination, "\" title=\"", title, "\">", to_html(children), "</a>"]
  end

  def to_html(%Node.Strong{children: children}) do
    ["<strong>", to_html(children), "</strong>"]
  end

  def to_html(%Node.Emph{children: children}) do
    ["<em>", to_html(children), "</em>"]
  end

  def to_html(%Node.List{children: children, list_data: %{type: :bullet}}) do
    ["\n", "<ul>", "\n", to_html(children), "\n", "</ul>", "\n"]
  end

  def to_html(%Node.List{children: children, list_data: %{type: :ordered, start: start}})
      when start == 1 do
    ["\n", "<ol>", "\n", to_html(children), "\n", "</ol>", "\n"]
  end

  def to_html(%Node.List{children: children, list_data: %{type: :ordered, start: start}}) do
    [
      "\n",
      "<ol start=\"",
      Integer.to_string(start),
      "\">",
      "\n",
      to_html(children),
      "\n",
      "</ol>",
      "\n"
    ]
  end

  def to_html(%Node.ListItem{children: children}) do
    ["<li>", to_html(children), "</li>", "\n"]
  end

  def to_html(%Node.Blockquote{children: children, callout: callout}) when is_binary(callout) do
    [
      "\n",
      "<blockquote class=\"callout-",
      callout,
      "\">",
      "\n",
      to_html(children),
      "\n",
      "</blockquote>",
      "\n"
    ]
  end

  def to_html(%Node.Blockquote{children: children}) do
    ["\n", "<blockquote>", "\n", to_html(children), "\n", "</blockquote>", "\n"]
  end

  def to_html(%Node.Paragraph{children: children, block: true}) do
    ["\n", "<p>", to_html(children), "</p>", "\n"]
  end

  def to_html(%Node.Paragraph{children: children, block: false}) do
    to_html(children)
  end

  def to_html(%Node.Break{}) do
    ["\n", "<hr />", "\n"]
  end

  def to_text(data), do: data |> to_text_iodata() |> IO.iodata_to_binary()

  defp to_text_iodata(nodes) when is_list(nodes), do: nodes |> Enum.map(&to_text_iodata/1)
  defp to_text_iodata(%Node.Text{content: content}), do: content

  defp to_text_iodata(%{children: children}),
    do: children |> to_text_iodata()

  defp dedup_newlines(list) do
    list
    |> dedup_newlines([])
  end

  defp dedup_newlines([], acc), do: Enum.reverse(acc)

  defp dedup_newlines(["\n" | t], acc) do
    acc =
      case acc do
        ["\n" | _] -> acc
        _ -> ["\n" | acc]
      end

    dedup_newlines(t, acc)
  end

  defp dedup_newlines([h | t], acc), do: dedup_newlines(t, [h | acc])

  defp strip_leading_newline(["\n" | t]), do: t
  defp strip_leading_newline(list), do: list
end
