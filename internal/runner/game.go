package runner

type Game struct {
	World  World
	Player Player
}

type State int

const (
	StateLocation State = iota
	StateEncounter
)

func (g Game) Location() Location {
	return g.World.Locations[g.Player.Location]
}

func (g Game) Encounter() Encounter {
	if g.Player.Encounter == "" {
		return Encounter{}
	}
	for _, e := range g.Location().Encounters {
		if e.ID == g.Player.Encounter {
			return e
		}
	}
	return Encounter{}
}

func (g Game) State() State {
	switch {
	case g.Player.Encounter == "":
		return StateLocation
	default:
		return StateEncounter
	}
}

func (g *Game) Reset() {
	g.Player.Location = g.World.TabulaRasa.Location
	g.Player.Encounter = ""
	g.Player.Inventory = map[string]int{}
	for k, v := range g.World.TabulaRasa.Inventory {
		g.Player.Inventory[k] = v
	}
}
