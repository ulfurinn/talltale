package storage

import (
	"io/ioutil"

	"github.com/ulfurinn/talltale/internal/runner"
	"gopkg.in/yaml.v2"
)

func LoadFromYML(f string) (w World, err error) {
	var yml []byte
	if yml, err = ioutil.ReadFile(f); err != nil {
		return
	}
	if err = yaml.Unmarshal(yml, &w); err != nil {
		return
	}
	return
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
