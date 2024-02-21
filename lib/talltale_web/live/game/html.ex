defmodule TalltaleWeb.GameLive.HTML do
  use TalltaleWeb, :html

  alias Tailmark.Node.Paragraph
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
    <%= @storyline.content %>
    """
  end

  def rich_text(%{content: list} = assigns) when is_list(list) do
    ~H"""
    <.rich_text :for={element <- @content} content={element} />
    """
  end

  def rich_text(%{content: %Paragraph{}} = assigns) do
    ~H"""
    <p class="paragraph">
      <.rich_text :for={element <- @content.children} content={element} />
    </p>
    """
  end

  def rich_text(%{content: %Text{}} = assigns) do
    ~H"""
    <%= @content.content %>
    """
  end
end
