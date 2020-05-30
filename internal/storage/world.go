package storage

type World struct {
	ID     string `yaml:"-" json:"id"`
	Global struct {
		Title string `yaml:"title" json:"title"`
	} `yaml:"global" json:"global"`
	Locations  map[string]Location `yaml:"locations" json:"locations,omitempty"`
	PlayerSeed struct {
		Stats    map[string]int `yaml:"stats" json:"stats"`
		Location string         `yaml:"location" json:"location"`
	} `yaml:"player_seed" json:"player_seed"`
	Stats map[string]Stat `yaml:"stats" json:"stats"`
}

type Stat struct {
	Name        string `yaml:"name" json:"name"`
	Description string `yaml:"description" json:"description"`
}

func (w *World) WithoutChildren() World {
	world := *w
	world.Locations = nil
	return world
}

func (w *World) normalise() {
	if w.PlayerSeed.Stats == nil {
		w.PlayerSeed.Stats = map[string]int{}
	}
	if w.Locations == nil {
		w.Locations = map[string]Location{}
	}
	for id, loc := range w.Locations {
		loc.normalise()
		loc.ID = id
		w.Locations[id] = loc
	}
}

func (w *World) AddLocation(id string, l Location) {
	l.ID = id
	w.Locations[id] = l
}
