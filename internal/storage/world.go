package storage

import "github.com/ulfurinn/talltale/internal/runner"

type World struct {
	ID     string `json:"id"`
	Global struct {
		Title string `yaml:"title" json:"title"`
	} `yaml:"global" json:"global"`
	Locations  map[string]Location `yaml:"locations" json:"locations,omitempty"`
	PlayerSeed struct {
		Stats    map[string]int `yaml:"stats" json:"stats"`
		Location string         `yaml:"location" json:"location"`
	} `yaml:"player_seed" json:"player_seed"`
}

func (w *World) StripChildren() {
	w.Locations = nil
}

func (w World) Parse() (world runner.World) {
	world.Title = w.Global.Title
	world.Locations = make(map[string]runner.Location)
	for id, l := range w.Locations {
		world.Locations[id] = l.Parse(id)
	}

	world.TabulaRasa.Location = w.PlayerSeed.Location
	world.TabulaRasa.Inventory = w.PlayerSeed.Stats

	return
}
