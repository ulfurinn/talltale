package talltale

type Game struct {
	ID     string
	World  World
	Player Player
}

func (g Game) Location() Location {
	return g.World.Locations[g.Player.Location]
}

func (g Game) Encounter() Encounter {
	for _, e := range g.Location().Encounters {
		if e.ID == g.Player.Encounter {
			return e
		}
	}
	return Encounter{}
}

type World struct {
	Title     string
	Locations map[string]Location
}

type Location struct {
	ID          string
	Name        string
	Description string
	Encounters  []Encounter
}

type Encounter struct {
	ID          string
	Name        string
	Description string
	Story       string
	Conditions  []Condition
	Choices     []Choice
}

func (e Encounter) Displayable(g Game) bool {
	if len(e.Conditions) == 0 {
		return true
	}
	for _, cond := range e.Conditions {
		if cond.Displayable(g.Player) {
			return true
		}
	}
	return false
}

func (e Encounter) Available(g Game) bool {
	if len(e.Conditions) == 0 {
		return true
	}
	for _, cond := range e.Conditions {
		if cond.Available(g.Player) {
			return true
		}
	}
	return false
}

type Choice struct {
	ID          string
	Name        string
	Description string
	Story       string
	Conditions  []Condition
	Effects     []Effect
}

func (c Choice) Displayable(g Game) bool {
	if len(c.Conditions) == 0 {
		return true
	}
	for _, cond := range c.Conditions {
		if cond.Displayable(g.Player) {
			return true
		}
	}
	return false
}

func (c Choice) Available(g Game) bool {
	if len(c.Conditions) == 0 {
		return true
	}
	for _, cond := range c.Conditions {
		if cond.Available(g.Player) {
			return true
		}
	}
	return false
}

type Condition interface {
	Displayable(Player) bool
	Available(Player) bool
}

type StatCondition struct {
	Stat            string
	Min             *int
	Max             *int
	HideUnavailable bool
}

func (c StatCondition) Available(p Player) bool {
	stat := p.Inventory[c.Stat]
	return (c.Min == nil || stat >= *c.Min) && (c.Max == nil || stat <= *c.Max)
}

func (c StatCondition) Displayable(p Player) bool {
	return c.Available(p) || !c.HideUnavailable
}

type Effect struct {
	Trials []Trial
	Pass   PlayerChange
	Fail   PlayerChange
}

type Trial func(Player) bool

type PlayerChange func(*Player)

type Story struct {
	Text string
}

func (e Effect) Success(player Player) bool {
	for _, trial := range e.Trials {
		if !trial(player) {
			return false
		}
	}
	return true
}

type Relocate struct {
	Location  string
	Encounter string
}

type Player struct {
	Location  string
	Encounter string
	Inventory map[string]int
}

type Stat struct {
	ID          string
	Name        string
	Description string
}
