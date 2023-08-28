defmodule Talltale.Tale do
  alias Talltale.Area
  alias Talltale.Card
  alias Talltale.Location

  defstruct [
    :areas,
    :qualities,
    :start
  ]

  def shuffle(tale, qualities) do
    area = tale.areas[qualities.area]
    location = area.locations[qualities.location]
    area.deck ++ location.deck
  end

  def talltale do
    %__MODULE__{
      areas: %{
        "start" => %Area{
          id: "start",
          title: "a narrow passage",
          description: "This is not how it begins.",
          deck: [],
          locations: %{
            "dream" => %Location{
              id: "dream",
              title: "a dream.",
              description: "Nothing but a dream.",
              deck: [
                %Card{frequency: 10, id: 1, title: "WAKE UP", effect: %{location: "dream?"}}
              ]
            },
            "dream?" => %Location{
              id: "dream?",
              title: "a dream..?",
              description: "Nothing but a dream. Surely.",
              deck: [
                %Card{
                  frequency: 10,
                  id: 2,
                  title: "WAKE UP!!!",
                  effect: %{location: "panic"}
                }
              ]
            }
          }
        }
      },
      qualities: [],
      start: %{
        area: "start",
        location: "dream",
        hand_size: 3
      }
    }
  end
end
