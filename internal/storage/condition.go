package storage

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
