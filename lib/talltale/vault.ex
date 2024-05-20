defmodule Talltale.Vault do
  @moduledoc "Parses an Obsidian vault containing a game definition."
  alias Talltale.Game.Challenge
  alias Tailmark.Document
  alias Tailmark.Node.{Blockquote, Break, Heading, Linebreak, Link, Paragraph, Text}
  alias Talltale.Game.{Area, Card, Deck, Location, Outcome, Quality, Storylet, Storyline, Tale}

  require Logger

  defstruct [
    :root,
    :notes,
    :slug,
    :title,
    starting_qualities: %{},
    qualities: %{},
    areas: %{},
    locations: %{},
    decks: %{},
    cards: %{},
    storylets: %{}
  ]

  defmacrop heading?(node, level) do
    quote do
      match?(%Heading.ATX{level: unquote(level)}, unquote(node)) or
        match?(%Heading.Setext{level: unquote(level)}, unquote(node))
    end
  end

  defmacrop callout?(node, callout) when is_binary(callout) do
    quote do
      match?(%Blockquote{callout: %{type: unquote(callout)}}, unquote(node))
    end
  end

  defmacrop link?(node) do
    quote do
      match?(%Link{}, unquote(node))
    end
  end

  defmacrop paragraph?(node) do
    quote do
      match?(%Paragraph{}, unquote(node))
    end
  end

  def load(path) do
    vault =
      %__MODULE__{root: path}
      |> parse()
      |> resolve()
      |> convert_to_ids()

    starting_location = vault.locations[vault.starting_qualities["location"]]

    %Tale{
      title: vault.title,
      areas: vault.areas,
      locations: vault.locations,
      decks: vault.decks,
      cards: vault.cards,
      qualities: vault.qualities,
      storylets: vault.storylets,
      start: vault.starting_qualities |> Map.put("area", starting_location.area_id)
    }
  end

  defp parse(vault = %__MODULE__{root: root}) do
    %__MODULE__{vault | notes: collect_notes(root)}
    |> parse_notes()
    |> process_notes()
  end

  defp resolve(vault) do
    vault
    |> resolve_starting_qualities()
    |> resolve_locations()
    |> resolve_areas()
    |> resolve_decks()
    |> resolve_cards()
    |> resolve_storylets()
  end

  defp convert_to_ids(vault) do
    %__MODULE__{
      vault
      | qualities: Map.new(vault.qualities, fn {_, quality} -> {quality.id, quality} end),
        areas: Map.new(vault.areas, fn {_, area} -> {area.id, area} end),
        locations: Map.new(vault.locations, fn {_, location} -> {location.id, location} end),
        decks: Map.new(vault.decks, fn {_, deck} -> {deck.id, deck} end),
        cards: Map.new(vault.cards, fn {_, card} -> {card.id, card} end),
        storylets: Map.new(vault.storylets, fn {_, storylet} -> {storylet.id, storylet} end)
    }
  end

  defp resolve_starting_qualities(vault) do
    qualities =
      vault.starting_qualities
      |> Enum.into(%{}, fn
        {"location", {:link, path}} -> {"location", Map.fetch!(vault.locations, path).id}
        pair -> pair
      end)

    %__MODULE__{vault | starting_qualities: qualities}
  end

  defp resolve_locations(vault) do
    vault.locations
    |> Enum.reduce(vault, fn {path, location}, vault ->
      resolve_location(path, location, vault)
    end)
  end

  defp resolve_location(path, location, vault) do
    location =
      %Location{
        location
        | storylines: resolve_storylines(location.storylines, vault),
          deck_id:
            case location.deck_id do
              nil -> nil
              {:link, path} -> Map.fetch!(vault.decks, path).id
            end
      }

    %__MODULE__{
      vault
      | locations: Map.put(vault.locations, path, location)
    }
  end

  defp resolve_areas(vault) do
    vault.areas
    |> Enum.reduce(vault, fn {path, area}, vault ->
      resolve_area(path, area, vault)
    end)
  end

  defp resolve_area(path, area, vault) do
    locations =
      area.location_ids
      |> Enum.into(%{}, fn path -> {path, Map.put(vault.locations[path], :area_id, area.id)} end)

    area = %Area{
      area
      | location_ids: Enum.map(locations, fn {_, l} -> l.id end),
        deck_id:
          case area.deck_id do
            nil -> nil
            {:link, path} -> Map.fetch!(vault.decks, path).id
          end
    }

    %__MODULE__{
      vault
      | locations: Map.merge(vault.locations, locations),
        areas: Map.put(vault.areas, path, area)
    }
  end

  defp resolve_storylines(storylines, vault) do
    storylines |> Enum.map(&resolve_storyline(&1, vault))
  end

  defp resolve_storyline(storyline, vault) do
    %Storyline{
      storyline
      | condition: resolve_condition(storyline.condition, vault)
    }
  end

  defp resolve_decks(vault) do
    vault.decks
    |> Enum.reduce(vault, fn {path, deck}, vault ->
      resolve_deck(path, deck, vault)
    end)
  end

  defp resolve_deck(path, deck, vault) do
    deck = %Deck{
      deck
      | card_ids: Enum.map(deck.card_ids, fn path -> Map.fetch!(vault.cards, path).id end)
    }

    %__MODULE__{
      vault
      | decks: Map.put(vault.decks, path, deck)
    }
  end

  defp resolve_cards(vault) do
    vault.cards
    |> Enum.reduce(vault, fn {path, card}, vault ->
      resolve_card(path, card, vault)
    end)
  end

  defp resolve_card(path, card, vault) do
    card = %Card{
      card
      | condition: resolve_condition(card.condition, vault),
        pass: resolve_outcome(card.pass, vault)
    }

    %__MODULE__{
      vault
      | cards: Map.put(vault.cards, path, card)
    }
  end

  defp resolve_storylets(vault) do
    vault.storylets
    |> Enum.reduce(vault, fn {path, storylet}, vault ->
      resolve_storylet(path, storylet, vault)
    end)
  end

  defp resolve_storylet(path, storylet, vault) do
    storylet = %Storylet{
      storylet
      | choices: Enum.map(storylet.choices, fn choice -> resolve_choice(choice, vault) end)
    }

    %__MODULE__{
      vault
      | storylets: Map.put(vault.storylets, path, storylet)
    }
  end

  defp resolve_choice(choice, vault) do
    %Card{
      choice
      | condition: resolve_condition(choice.condition, vault),
        challenges: resolve_challenges(choice.challenges, vault),
        pass: resolve_outcome(choice.pass, vault),
        fail: resolve_outcome(choice.fail, vault)
    }
  end

  defp resolve_condition(nil, _), do: nil

  defp resolve_condition(storyline = %Blockquote{callout: %{type: "when"}}, vault) do
    storyline
    |> reduce_walk("", fn
      %Link{destination: destination}, acc ->
        %Quality{variable: variable} = Map.fetch!(vault.qualities, normalize_uri(destination))
        {:return, acc <> variable}

      %Text{content: content}, acc ->
        {:return, acc <> content}

      _, acc ->
        {:cont, acc}
    end)
  end

  defp resolve_challenges(challenges, vault) do
    challenges
    |> Enum.map(&resolve_challenge(&1, vault))
  end

  defp resolve_challenge(challenge, vault) do
    %Blockquote{children: [paragraph = %Paragraph{}]} = challenge

    case paragraph.children do
      [%Link{destination: quality}, %Linebreak{}, %Text{content: expression}] ->
        %Challenge{
          quality: Map.fetch!(vault.qualities, normalize_uri(quality)),
          generator_expression: expression
        }
    end
  end

  defp resolve_outcome(outcome, vault) do
    %Outcome{
      outcome
      | effects: resolve_effects(outcome.effects, vault)
    }
  end

  defp resolve_effects(nodes, vault) do
    Enum.map(nodes, &resolve_effect(&1, vault))
  end

  defp resolve_effect(quality = %Blockquote{callout: %{type: "quality"}}, vault) do
    expression =
      quality
      |> reduce_walk("", fn
        %Link{destination: destination}, acc ->
          %Quality{variable: variable} = Map.fetch!(vault.qualities, normalize_uri(destination))
          {:return, acc <> variable}

        %Text{content: content}, acc ->
          {:return, acc <> content}

        _, acc ->
          {:cont, acc}
      end)

    {:quality, expression}
  end

  defp resolve_effect(location = %Blockquote{callout: %{type: "location"}}, vault) do
    link = location |> find(&link?/1)
    {:location, vault.locations[normalize_uri(link.destination)].id}
  end

  defp resolve_effect(storylet = %Blockquote{callout: %{type: "storylet"}}, vault) do
    link = storylet |> find(&link?/1)

    {:storylet, vault.storylets[normalize_uri(link.destination)].id}
  end

  defp collect_notes(root) do
    prefix = root <> "/"

    Path.wildcard("#{root}/**/*.md")
    |> Enum.map(fn path -> {short_path(path, prefix), path} end)
    |> Enum.reject(&hidden?/1)
    |> Enum.into(%{})
  end

  defp short_path(path, prefix) do
    path
    |> String.trim_leading(prefix)
    |> String.trim_trailing(".md")
  end

  defp hidden?({path, _}) do
    path
    |> Path.split()
    |> Enum.any?(&String.starts_with?(&1, "_"))
  end

  defp parse_notes(vault) do
    notes =
      vault.notes
      |> Enum.map(fn {path, absolute} ->
        document =
          absolute
          |> File.read!()
          |> Tailmark.Parser.document()
          |> ensure_has_id(absolute)
          |> Tailmark.Document.compress_text()

        {path, document}
      end)

    %__MODULE__{vault | notes: notes}
  end

  defp ensure_has_id(document = %{frontmatter: %{"type" => _, "id" => id}}, _)
       when is_binary(id),
       do: document

  defp ensure_has_id(document = %{frontmatter: %{"type" => _}}, path) do
    id = Uniq.UUID.uuid7()
    frontmatter = Map.put(document.frontmatter, "id", id)
    content = [Ymlr.document!(frontmatter, sort_maps: true), "---\n", document.source]
    File.write!(path, content)
    %Document{document | frontmatter: frontmatter}
  end

  defp ensure_has_id(document, _), do: document

  defp process_notes(vault) do
    vault.notes
    |> Enum.reduce(vault, fn {path, document}, vault ->
      frontmatter = parse_frontmatter_links(document.frontmatter)
      process_note(path, document, frontmatter, vault)
    end)
    |> then(&reset_notes/1)
  end

  defp reset_notes(vault), do: %__MODULE__{vault | notes: nil}

  defp process_note(path, document, frontmatter, vault)

  defp process_note(_path, document, frontmatter = %{"type" => "start"}, vault) do
    %__MODULE__{
      vault
      | slug: document.frontmatter["slug"],
        title: document.frontmatter["title"],
        starting_qualities: Map.drop(frontmatter, ["type", "slug", "title"])
    }
  end

  defp process_note(path, _document, frontmatter = %{"type" => "quality"}, vault) do
    quality = %Quality{
      id: frontmatter["id"],
      title: frontmatter["title"] || basename(path),
      variable: frontmatter["variable"],
      type: frontmatter["datatype"],
      category: frontmatter["category"],
      slot: frontmatter["slot"],
      group: frontmatter["group"],
      description: frontmatter["description"]
    }

    %__MODULE__{
      vault
      | qualities: Map.put(vault.qualities, path, quality)
    }
  end

  defp process_note(path, document, frontmatter = %{"type" => "area"}, vault) do
    locations =
      document
      |> section("Locations")
      |> reduce([], fn
        %Link{destination: destination}, acc -> [normalize_uri(destination) | acc]
        _, acc -> acc
      end)
      |> Enum.reverse()

    area = %Area{
      id: frontmatter["id"],
      title: basename(path),
      location_ids: locations,
      deck_id: frontmatter["deck"]
    }

    %__MODULE__{
      vault
      | areas: Map.put(vault.areas, path, area)
    }
  end

  defp process_note(path, document, frontmatter = %{"type" => "location"}, vault) do
    title = document |> find(&heading?(&1, 1))

    title =
      cond do
        title != nil -> Tailmark.Writer.to_text(title)
        frontmatter["title"] != nil -> frontmatter["title"]
        true -> basename(path)
      end

    storylines =
      document
      |> section("Storyline")
      |> Enum.chunk_by(&match?(%Break{}, &1))
      |> Enum.reject(&match?([%Break{}], &1))
      |> Enum.map(&process_storyline/1)

    location =
      %Location{
        id: frontmatter["id"],
        title: title,
        storylines: storylines,
        deck_id: frontmatter["deck"]
      }

    %__MODULE__{
      vault
      | locations: Map.put(vault.locations, path, location)
    }
  end

  defp process_note(path, document, frontmatter = %{"type" => "deck"}, vault) do
    cards =
      document
      |> section("Cards")
      |> reduce([], fn
        %Link{destination: destination}, acc -> [normalize_uri(destination) | acc]
        _, acc -> acc
      end)

    deck = %Deck{
      id: frontmatter["id"],
      title: basename(path),
      card_ids: cards
    }

    %__MODULE__{
      vault
      | decks: Map.put(vault.decks, path, deck)
    }
  end

  defp process_note(path, document, frontmatter = %{"type" => "card"}, vault) do
    title = document |> find(&heading?(&1, 1))

    title =
      case title do
        nil -> basename(path)
        node -> Tailmark.Writer.to_text(node)
      end

    condition = document |> find(&callout?(&1, "when"))

    effects =
      document
      |> select(fn node ->
        callout?(node, "quality") or callout?(node, "location") or callout?(node, "storylet")
      end)

    storyline = document.children |> Enum.filter(&paragraph?/1)

    card =
      %Card{
        id: frontmatter["id"],
        title: title,
        frequency: frontmatter["frequency"],
        sticky: Map.get(frontmatter, "sticky", false),
        condition: condition,
        pass: %Outcome{kind: :pass, storyline: storyline, effects: effects}
      }

    %__MODULE__{
      vault
      | cards: Map.put(vault.cards, path, card)
    }
  end

  defp process_note(path, document, frontmatter = %{"type" => "storylet"}, vault) do
    choices =
      document
      |> section("Choices")
      |> sections(2)
      |> Enum.map(&process_storylet_choice/1)

    storylet = %Storylet{
      id: frontmatter["id"],
      title: basename(path),
      choices: choices
    }

    %__MODULE__{
      vault
      | storylets: Map.put(vault.storylets, path, storylet)
    }
  end

  defp process_note(_, _, _, vault), do: vault

  defp process_storyline(nodes) do
    storyline =
      nodes
      |> Enum.reduce(%Storyline{text: []}, fn node, storyline ->
        case node do
          %Blockquote{callout: %{type: "when"}} ->
            %Storyline{storyline | condition: node}

          %Paragraph{} ->
            %Storyline{storyline | text: [node | storyline.text]}

          _ ->
            Logger.warning("Unexpected element in storyline: #{inspect(node)}")
        end
      end)

    text =
      storyline.text
      |> Enum.reverse()

    %Storyline{storyline | text: text}
  end

  def process_storylet_choice(nodes) do
    title = nodes |> find(&heading?(&1, 2))

    condition = nodes |> find(&callout?(&1, "when"))

    challenges = nodes |> select(&callout?(&1, "challenge"))

    {pass, fail} =
      if Enum.any?(challenges) do
        nodes |> process_choice_with_challenge()
      else
        nodes |> process_choice_without_challenge()
      end

    own_nodes = nodes |> Enum.take_while(&(not heading?(&1, 3)))

    %Card{
      id: Uniq.UUID.uuid7(),
      title: Tailmark.Writer.to_text(title),
      text: own_nodes |> Enum.filter(&paragraph?/1),
      condition: condition,
      challenges: challenges,
      pass: pass,
      fail: fail
    }
  end

  defp process_choice_with_challenge(nodes) do
    {nodes |> section("Pass") |> process_choice(:pass),
     nodes |> section("Fail") |> process_choice(:fail)}
  end

  defp process_choice_without_challenge(nodes) do
    {nodes |> section("Pass") |> process_choice(:pass), %Outcome{}}
  end

  defp process_choice(nodes, kind) do
    effects =
      nodes
      |> select(fn node ->
        callout?(node, "quality") or callout?(node, "location") or callout?(node, "storylet")
      end)

    text = nodes |> Enum.filter(&paragraph?/1)

    %Outcome{
      kind: kind,
      storyline: text |> process_storyline(),
      effects: effects
    }
  end

  defp parse_frontmatter_links(nil) do
    %{}
  end

  defp parse_frontmatter_links(frontmatter) do
    frontmatter
    |> Enum.into(%{}, fn
      pair = {k, v} when is_binary(v) ->
        case Tailmark.InlineParser.parse(v) do
          %Paragraph{
            children: [link = %Link{}]
          } ->
            {k, {:link, normalize_uri(link.destination)}}

          _ ->
            pair
        end

      pair ->
        pair
    end)
  end

  defp basename(string) do
    string |> Path.basename(".md")
  end

  defp section(children, content)

  defp section(%Document{children: children}, content), do: section(children, content)
  defp section([], _), do: []

  defp section([section = %mod{children: [%Text{content: content}]} | children], content)
       when mod in [Heading.ATX, Heading.Setext] do
    children
    |> Enum.take_while(fn subnode = %mod{} ->
      mod not in [Heading.ATX, Heading.Setext] || subnode.level > section.level
    end)
  end

  defp section([_ | tail], content), do: section(tail, content)

  defp sections(nodes, level), do: sections(nodes, level, [])

  defp sections([heading | rest], level, acc) do
    if heading?(heading, ^level) do
      {children, rest} = rest |> Enum.split_while(&(not heading?(&1, ^level)))
      sections(rest, level, [[heading | children] | acc])
    else
      sections(rest, level, acc)
    end
  end

  defp sections([], _, acc), do: Enum.reverse(acc)

  defp reduce(nodes, acc, fun) do
    reduce_while(nodes, acc, fn node, acc -> {:cont, fun.(node, acc)} end)
  end

  defp reduce_while(node_or_nodes, acc, fun) do
    reduce_while1(node_or_nodes, acc, fun) |> elem(1)
  end

  defp reduce_while1([], acc, _), do: {:cont, acc}

  defp reduce_while1([node | nodes], acc, fun) do
    res = node |> reduce_while1(acc, fun)

    case res do
      {:halt, _} ->
        res

      {:cont, acc} ->
        reduce_while1(nodes, acc, fun)
    end
  end

  defp reduce_while1(node, acc, fun) do
    res = node |> fun.(acc)

    case res do
      {:halt, _} ->
        res

      {:cont, acc} ->
        case node do
          %{children: children} ->
            reduce_while1(children, acc, fun)

          _ ->
            res
        end
    end
  end

  defp reduce_walk(node_or_nodes, acc, fun)

  defp reduce_walk([], acc, _), do: acc

  defp reduce_walk([node | nodes], acc, fun) do
    reduce_walk(nodes, reduce_walk(node, acc, fun), fun)
  end

  defp reduce_walk(node, acc, fun) do
    res = node |> fun.(acc)

    case res do
      {:cont, acc} ->
        case node do
          %{children: children} ->
            reduce_walk(children, acc, fun)

          _ ->
            acc
        end

      {:return, acc} ->
        acc
    end
  end

  defp find(node_or_nodes, fun) do
    reduce_while(node_or_nodes, nil, fn node, acc ->
      if node |> fun.() do
        {:halt, node}
      else
        {:cont, acc}
      end
    end)
  end

  defp select(node_or_nodes, fun) do
    node_or_nodes
    |> reduce([], fn node, acc ->
      if node |> fun.() do
        [node | acc]
      else
        acc
      end
    end)
    |> Enum.reverse()
  end

  defp normalize_uri(uri) do
    uri
    |> URI.decode()
    |> String.trim_trailing(".md")
  end
end
