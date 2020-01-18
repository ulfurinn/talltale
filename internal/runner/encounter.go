package runner

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
