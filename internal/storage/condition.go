package storage

import "github.com/ulfurinn/talltale/internal/runner"

type Condition struct {
	StatCondition *StatConditionSet `yaml:"stat" json:"stat"`
}

type StatConditionSet map[string]StatCondition

type StatCondition struct {
	Stat string `yaml:"-" json:"-"`
	Min  *int   `yaml:"min" json:"min"`
	Max  *int   `yaml:"max" json:"max"`
	Hide bool   `yaml:"hide" json:"hide"`
}

func (cond Condition) Parse() (condition runner.Condition) {
	switch {
	case cond.StatCondition != nil:
		return cond.StatCondition.Parse()

	default:
		panic("no valid conditions")
	}
}

func (cond *Condition) normalise() {}

func (scs StatConditionSet) Parse() runner.Condition {
	sub := make([]runner.Condition, 0, len(scs))
	for stat, c := range scs {
		c.Stat = stat
		sub = append(sub, c.Parse())
	}
	return runner.AggregateCondition{
		Conditions: sub,
	}
}

func (sc StatCondition) Parse() (condition runner.StatCondition) {
	condition.Stat = sc.Stat
	condition.Min = sc.Min
	condition.Max = sc.Max
	condition.HideUnavailable = sc.Hide
	return
}
