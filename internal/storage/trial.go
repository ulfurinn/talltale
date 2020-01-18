package storage

import "github.com/ulfurinn/talltale/internal/runner"

type Trial struct {
	Automatic interface{} `yaml:"automatic"`
}

func (t Trial) Parse() (trial runner.Trial) {
	switch {
	case t.Automatic != nil:
		return runner.AutomaticPass

	default:
		return runner.AutomaticFail
	}
}
