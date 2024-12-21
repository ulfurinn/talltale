defmodule TalltaleWeb.GameLive.HTML do
  use TalltaleWeb, :html
  alias Tailmark.Node.Emph
  alias Tailmark.Node.Heading.ATX
  alias Tailmark.Node.Linebreak
  alias Tailmark.Node.Paragraph
  alias Tailmark.Node.Strong
  alias Tailmark.Node.Text
  alias Talltale.Game

  def storyline(%{game: _, location: _} = assigns) do
    ~H"""
    <div class="storyline">
      <div class="content">
        <.storyline storyline={Game.build_storyline(@game, @game.tale.locations[@location])} />
      </div>
    </div>
    """
  end

  def storyline(%{storyline: list} = assigns) when is_list(list) do
    ~H"""
    <.storyline :for={element <- @storyline} storyline={element} />
    """
  end

  def storyline(%{storyline: %Talltale.Game.Storyline{}} = assigns) do
    ~H"""
    <.storyline storyline={@storyline.text} />
    """
  end

  def storyline(%{storyline: %Paragraph{}} = assigns) do
    rich_text(%{content: assigns.storyline})
  end

  def storyline(%{storyline: %Text{content: _}} = assigns) do
    ~H"""
    {@storyline.content}
    """
  end

  def rich_text(%{content: list} = assigns) when is_list(list) do
    ~H"""
    <.rich_text :for={element <- @content} content={element} />
    """
  end

  def rich_text(%{content: %Paragraph{}} = assigns) do
    ~H"""
    <p class="paragraph"><.rich_text :for={element <- @content.children} content={element} /></p>
    """
  end

  def rich_text(%{content: %ATX{level: 1}} = assigns) do
    ~H"""
    <h1><.rich_text :for={element <- @content.children} content={element} /></h1>
    """
  end

  def rich_text(%{content: %ATX{level: 2}} = assigns) do
    ~H"""
    <h2><.rich_text :for={element <- @content.children} content={element} /></h2>
    """
  end

  def rich_text(%{content: %ATX{level: 3}} = assigns) do
    ~H"""
    <h3><.rich_text :for={element <- @content.children} content={element} /></h3>
    """
  end

  def rich_text(%{content: %ATX{level: 4}} = assigns) do
    ~H"""
    <h4><.rich_text :for={element <- @content.children} content={element} /></h4>
    """
  end

  def rich_text(%{content: %ATX{level: 5}} = assigns) do
    ~H"""
    <h5><.rich_text :for={element <- @content.children} content={element} /></h5>
    """
  end

  def rich_text(%{content: %ATX{level: 6}} = assigns) do
    ~H"""
    <h6><.rich_text :for={element <- @content.children} content={element} /></h6>
    """
  end

  def rich_text(%{content: %Text{}} = assigns) do
    ~H"""
    {@content.content}
    """
  end

  def rich_text(%{content: %Emph{}} = assigns) do
    ~H"""
    <em><.rich_text :for={element <- @content.children} content={element} /></em>
    """
  end

  def rich_text(%{content: %Strong{}} = assigns) do
    ~H"""
    <strong><.rich_text :for={element <- @content.children} content={element} /></strong>
    """
  end

  def rich_text(%{content: %Linebreak{}} = assigns) do
    ~H"""
    <br />
    """
  end
end
