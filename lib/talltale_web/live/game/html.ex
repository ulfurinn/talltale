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

  def storyline(%{storyline: %Talltale.Game.Storyline{text: text}} = assigns) do
    ~H"""
    <.storyline storyline={text} />
    """
  end

  def storyline(%{storyline: %Paragraph{children: children}} = assigns) do
    ~H"""
    <div class="paragraph">
      <.storyline storyline={children} />
    </div>
    """
  end

  def storyline(%{storyline: %Text{content: _}} = assigns) do
    ~H"""
    <%= @storyline.content %>
    """
  end
end
