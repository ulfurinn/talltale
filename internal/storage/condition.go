package storage

import "github.com/ulfurinn/talltale/internal/runner"

type Condition struct {
	StatCondition *StatConditionSet `yaml:"stat"`
}

type StatConditionSet map[string]StatCondition

type StatCondition struct {
	Stat string `yaml:"-"`
	Min  *int   `yaml:"min"`
	Max  *int   `yaml:"max"`
	Hide bool   `yaml:"hide"`
}

func (cond Condition) Parse() (condition runner.Condition) {
	switch {
	case cond.StatCondition != nil:
		return cond.StatCondition.Parse()

	default:
		panic("no valid conditions")
	}
}

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
