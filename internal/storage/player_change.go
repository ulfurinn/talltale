package storage

import "github.com/ulfurinn/talltale/internal/runner"

type PlayerChangeSet []PlayerChange

type PlayerChange struct {
	StatChange *StatChange `yaml:"stat_change"`
	Redirect   *Redirect   `yaml:"redirect"`
}

type StatChange struct {
	Stat       string `yaml:"stat"`
	Change     int    `yaml:"change"`
	NoLessThan *int   `yaml:"no_less_than"`
	NoMoreThan *int   `yaml:"no_more_than"`
	Absolute   bool   `yaml:"absolute"`
}

type Redirect struct {
	Location string `yaml:"location"`
}

func (pcs PlayerChangeSet) Parse() (playerChange runner.PlayerChange) {
	funcs := []runner.PlayerChange{}
	for _, c := range pcs {
		if f := c.Parse(); f != nil {
			funcs = append(funcs, f)
		}
	}
	return runner.AggregatePlayerChange(funcs)
}

func (pc PlayerChange) Parse() (playerChange runner.PlayerChange) {
	switch {
	case pc.StatChange != nil:
		return pc.StatChange.Parse()
	case pc.Redirect != nil:
		return pc.Redirect.Parse()
	default:
		return nil
	}
}

func (sc StatChange) Parse() runner.PlayerChange {
	return func(player *runner.Player) {
		currentValue := player.Inventory[sc.Stat]
		var newValue int
		if sc.Absolute {
			newValue = sc.Change
		} else {
			newValue = currentValue + sc.Change
			if sc.NoMoreThan != nil && newValue > *sc.NoMoreThan {
				newValue = *sc.NoMoreThan
			}
			if sc.NoLessThan != nil && newValue < *sc.NoLessThan {
				newValue = *sc.NoLessThan
			}
		}
		player.Inventory[sc.Stat] = newValue
	}
}

func (r Redirect) Parse() runner.PlayerChange {
	return func(player *runner.Player) {
		player.Location = r.Location
	}
}
