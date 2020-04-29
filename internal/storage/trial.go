package storage

import "github.com/ulfurinn/talltale/internal/runner"

type Trial struct {
	Automatic bool `yaml:"automatic" json:"automatic"`
}

func (t *Trial) Parse() (trial runner.Trial) {
	switch {
	case t.Automatic:
		return runner.AutomaticPass

	default:
		return runner.AutomaticFail
	}
}
