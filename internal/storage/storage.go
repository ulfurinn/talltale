package storage

import (
	"fmt"
	"io/ioutil"
	"os"
	"sync"

	"gopkg.in/yaml.v2"
)

var (
	worlds   map[string]World
	worldsMx sync.Mutex
)

func Load() (err error) {
	worldsMx.Lock()
	defer worldsMx.Unlock()

	worlds = map[string]World{}

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
			if world, err := loadWorld(dir); err == nil {
				fmt.Fprintln(os.Stdout, "loaded", world.ID, world.Global.Title)
				worlds[world.ID] = world
			}

		}
	}

	return
}

func Worlds() map[string]World {
	return worlds
}

func GetWorld(id string) (world World, err error) {
	var ok bool
	if world, ok = worlds[id]; !ok {
		err = fmt.Errorf("world %s does not exist", id)
	}
	return
}

func loadWorld(name string) (w World, err error) {
	w, err = loadFromYML("worlds/" + name + "/world.yml")
	w.ID = name
	return
}

func loadFromYML(f string) (w World, err error) {
	fmt.Fprintln(os.Stdout, "loading", f)
	var yml []byte
	if yml, err = ioutil.ReadFile(f); err != nil {
		return
	}
	if err = yaml.Unmarshal(yml, &w); err != nil {
		return
	}
	return
}
