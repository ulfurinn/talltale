package runner

type Encounter struct {
	ID          string
	Name        string
	Description string
	Story       string
	Conditions  []Condition
	Choices     []Choice
}

func (e Encounter) Displayable(p Player) bool {
	if len(e.Conditions) == 0 {
		return true
	}
	for _, cond := range e.Conditions {
		if cond.Displayable(p) {
			return true
		}
	}
	return false
}

func (e Encounter) Available(p Player) bool {
	if len(e.Conditions) == 0 {
		return true
	}
	for _, cond := range e.Conditions {
		if cond.Available(p) {
			return true
		}
	}
	return false
}
