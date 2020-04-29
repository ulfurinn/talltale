package runner

type Choice struct {
	ID          string
	Name        string
	Description string
	Story       string
	Conditions  []Condition
	Effects     []Effect
}

func (c Choice) Displayable(p Player) bool {
	if len(c.Conditions) == 0 {
		return true
	}
	for _, cond := range c.Conditions {
		if cond.Displayable(p) {
			return true
		}
	}
	return false
}

func (c Choice) Available(p Player) bool {
	if len(c.Conditions) == 0 {
		return true
	}
	for _, cond := range c.Conditions {
		if cond.Available(p) {
			return true
		}
	}
	return false
}
