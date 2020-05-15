package storage

import "github.com/ulfurinn/talltale/internal/runner"

type Condition struct {
	StatCondition StatConditionSet `yaml:"stat" json:"stat"`
}

type StatConditionSet map[string]StatCondition

type StatCondition struct {
	Stat string `yaml:"-" json:"-"`
	Min  *int   `yaml:"min" json:"min"`
	Max  *int   `yaml:"max" json:"max"`
	Hide bool   `yaml:"hide" json:"hide"`
}

func (cond *Condition) Parse() (runner.Condition, error) {
	switch {
	case cond.StatCondition != nil:
		return cond.StatCondition.Parse()

	default:
		panic("no valid conditions")
	}
}

func (cond *Condition) normalise() {}

func (scs StatConditionSet) Parse() (runner.AggregateCondition, error) {
	sub := make([]runner.Condition, 0, len(scs))
	for stat, c := range scs {
		c.Stat = stat
		if c, err := c.Parse(); err == nil {
			sub = append(sub, c)
		} else {
			return runner.AggregateCondition{}, err
		}
	}
	return runner.AggregateCondition{
		Conditions: sub,
	}, nil
}

func (sc *StatCondition) Parse() (runner.StatCondition, error) {
	return runner.StatCondition{
		Stat:            sc.Stat,
		Min:             sc.Min,
		Max:             sc.Max,
		HideUnavailable: sc.Hide,
	}, nil
}
