package storage

import (
	"io/ioutil"
	"os"

	"github.com/ulfurinn/talltale/internal/runner"
	"gopkg.in/yaml.v2"
)

func Worlds() (worlds []World, err error) {
	worlds = []World{}

	var f *os.File
	if f, err = os.Open("worlds"); err != nil {
		return
	}
	defer f.Close()

	var dirs []string
	if dirs, err = f.Readdirnames(-1); err != nil {
		return
	}
	for _, dir := range dirs {
		if _, err := os.Stat("worlds/" + dir + "/world.yml"); err == nil {
			if world, err := LoadWorld(dir); err == nil {
				worlds = append(worlds, world)
			}

		}
	}

	return
}

func LoadWorld(name string) (w World, err error) {
	w, err = LoadFromYML("worlds/" + name + "/world.yml")
	w.ID = name
	return
}

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
