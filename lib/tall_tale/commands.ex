defmodule TallTale.Commands do
  defmodule Transition do
    alias __MODULE__
    defstruct [:id, :target, :type, :after, :duration]

    def fade_out(target, duration \\ nil) do
      %Transition{
        id: Uniq.UUID.uuid7(),
        target: target,
        type: "fade-out",
        after: "hide",
        duration: duration
      }
    end

    def fade_in(target, duration \\ nil) do
      %Transition{
        id: Uniq.UUID.uuid7(),
        target: target,
        type: "fade-in",
        after: "show",
        duration: duration
      }
    end
  end

  defmodule SetScreen do
    alias __MODULE__
    defstruct [:screen_id]

    def new(screen_id) do
      %SetScreen{screen_id: screen_id}
    end
  end
end
