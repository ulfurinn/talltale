package talltale

import (
	"io/ioutil"

	"gopkg.in/yaml.v2"
)

func LoadWorld(f string) (s StoredWorld, err error) {
	var yml []byte
	if yml, err = ioutil.ReadFile(f); err != nil {
		return
	}
	if err = yaml.Unmarshal(yml, &s); err != nil {
		return
	}
	return
}

type StoredWorld struct {
	Global struct {
		Title string `yaml:"title"`
	} `yaml:"global"`
	Locations  map[string]StoredLocation `yaml:"locations"`
	PlayerSeed struct {
		Stats    map[string]int `yaml:"stats"`
		Location string         `yaml:"location"`
	} `yaml:"player_seed"`
}

type StoredLocation struct {
	Name        string            `yaml:"name"`
	Description string            `yaml:"description"`
	Encounters  []StoredEncounter `yaml:"encounters"`
}

type StoredEncounter struct {
	ID          string                     `yaml:"id"`
	Name        string                     `yaml:"name"`
	Description string                     `yaml:"description"`
	Story       string                     `yaml:"story"`
	Conditions  map[string]StoredCondition `yaml:"conditions"`
	Choices     []StoredChoice             `yaml:"choices"`
}

type StoredCondition struct {
	StatCondition *StoredStatCondition `yaml:"stat_condition"`
}

type StoredStatCondition struct {
	Stat string `yaml:"stat"`
	Min  *int   `yaml:"min"`
	Max  *int   `yaml:"max"`
	Hide bool   `yaml:"hide"`
}

type StoredChoice struct {
	ID          string                     `yaml:"id"`
	Name        string                     `yaml:"name"`
	Description string                     `yaml:"description"`
	Story       string                     `yaml:"story"`
	Conditions  map[string]StoredCondition `yaml:"conditions"`
	Effects     []StoredEffect             `yaml:"effects"`
}

type StoredEffect struct {
	Trials []StoredTrial      `yaml:"trials"`
	Pass   StoredPlayerChange `yaml:"pass"`
	Fail   StoredPlayerChange `yaml:"fail"`
}

type StoredTrial struct {
	Automatic *struct{} `yaml:"automatic"`
}

type StoredPlayerChange []struct {
	StatChange *StoredStatChange `yaml:"stat_change"`
	Redirect   *StoredRedirect   `yaml:"redirect"`
}

type StoredStatChange struct {
	Stat       string `yaml:"stat"`
	Change     int    `yaml:"change"`
	NoLessThan *int   `yaml:"no_less_than"`
	NoMoreThan *int   `yaml:"no_more_than"`
	Absolute   bool   `yaml:"absolute"`
}

type StoredRedirect struct {
	Location string `yaml:"location"`
}

func (s StoredWorld) Parse() (world World, player Player) {
	world.Title = s.Global.Title
	world.Locations = make(map[string]Location)
	for id, l := range s.Locations {
		location := l.Parse(id)
		world.Locations[location.ID] = location
	}

	player.Location = s.PlayerSeed.Location
	player.Inventory = make(map[string]int)
	for stat, value := range s.PlayerSeed.Stats {
		player.Inventory[stat] = value
	}
	return
}

func (l StoredLocation) Parse(id string) (location Location) {
	location.ID = id
	location.Name = l.Name
	location.Description = l.Description
	for _, e := range l.Encounters {
		location.Encounters = append(location.Encounters, e.Parse())
	}
	return
}

func (e StoredEncounter) Parse() (encounter Encounter) {
	encounter.ID = e.ID
	encounter.Name = e.Name
	encounter.Description = e.Description
	encounter.Story = e.Story
	for _, cond := range e.Conditions {
		encounter.Conditions = append(encounter.Conditions, cond.Parse())
	}
	for _, choice := range e.Choices {
		encounter.Choices = append(encounter.Choices, choice.Parse())
	}
	return
}

func (c StoredChoice) Parse() (choice Choice) {
	choice.ID = c.ID
	choice.Name = c.Name
	choice.Description = c.Description
	choice.Story = c.Story
	for _, cond := range c.Conditions {
		choice.Conditions = append(choice.Conditions, cond.Parse())
	}
	for _, effect := range c.Effects {
		choice.Effects = append(choice.Effects, effect.Parse())
	}
	return
}

func (cond StoredCondition) Parse() (condition Condition) {
	switch {
	case cond.StatCondition != nil:
		return cond.StatCondition.Parse()

	default:
		panic("no valid conditions")
	}
}

func (sc StoredStatCondition) Parse() (condition StatCondition) {
	condition.Stat = sc.Stat
	condition.Min = sc.Min
	condition.Max = sc.Max
	condition.HideUnavailable = sc.Hide
	return
}

func (e StoredEffect) Parse() (effect Effect) {
	for _, t := range e.Trials {
		effect.Trials = append(effect.Trials, t.Parse())
	}
	effect.Pass = e.Pass.Parse()
	effect.Fail = e.Fail.Parse()
	return
}

func (t StoredTrial) Parse() (trial Trial) {
	switch {
	case t.Automatic != nil:
		return AutomaticPass

	default:
		return AutomaticFail
	}
}

func (pc StoredPlayerChange) Parse() (playerChange PlayerChange) {
	if pc == nil {
		return nil
	}
	funcs := []PlayerChange{}
	for _, c := range pc {
		var f PlayerChange
		switch {
		case c.StatChange != nil:
			f = c.StatChange.Parse()
		case c.Redirect != nil:
			f = c.Redirect.Parse()
		}
		if f != nil {
			funcs = append(funcs, f)
		}
	}
	return AggregatePlayerChange(funcs)
}

func (sc StoredStatChange) Parse() PlayerChange {
	return func(player *Player) {
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

func (r StoredRedirect) Parse() PlayerChange {
	return func(player *Player) {
		player.Location = r.Location
	}
}

var AutomaticPass Trial = func(Player) bool { return true }
var AutomaticFail Trial = func(Player) bool { return false }

func AggregatePlayerChange(funcs []PlayerChange) PlayerChange {
	return func(p *Player) {
		for _, f := range funcs {
			f(p)
		}
	}
}
