package runner

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

type AggregateCondition struct {
	Conditions []Condition
}

func (ac AggregateCondition) Available(p Player) bool {
	for _, c := range ac.Conditions {
		if !c.Available(p) {
			return false
		}
	}
	return true
}

func (ac AggregateCondition) Displayable(p Player) bool {
	for _, c := range ac.Conditions {
		if !c.Displayable(p) {
			return false
		}
	}
	return true
}
