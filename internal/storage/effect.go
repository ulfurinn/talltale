package storage

import "github.com/ulfurinn/talltale/internal/runner"

type Effect struct {
	Trials []Trial         `yaml:"trials"`
	Pass   PlayerChangeSet `yaml:"pass"`
	Fail   PlayerChangeSet `yaml:"fail"`
}

func (e Effect) Parse() (effect runner.Effect) {
	for _, t := range e.Trials {
		effect.Trials = append(effect.Trials, t.Parse())
	}
	effect.Pass = e.Pass.Parse()
	effect.Fail = e.Fail.Parse()
	return
}
