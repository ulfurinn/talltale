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
	worldsMx sync.RWMutex
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
	worldsMx.RLock()
	defer worldsMx.RUnlock()
	var ok bool
	if world, ok = worlds[id]; !ok {
		err = fmt.Errorf("world %s does not exist", id)
	}
	return
}

func UpdateWorld(id string, f func(w *World)) (err error) {
	worldsMx.Lock()
	defer worldsMx.Unlock()
	w := worlds[id]
	f(&w)
	if err = Commit(id, w); err == nil {
		worlds[id] = w
	}
	return
}

func Commit(id string, w World) (err error) {
	var f *os.File
	if f, err = os.Create("worlds/" + id + "/world.yml"); err != nil {
		return
	}
	defer f.Close()
	encoder := yaml.NewEncoder(f)
	err = encoder.Encode(w)
	return
}

func loadWorld(id string) (w World, err error) {
	w, err = loadFromYML("worlds/" + id + "/world.yml")
	w.ID = id
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
	w.normalise()
	return
}
