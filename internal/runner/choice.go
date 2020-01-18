package runner

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
