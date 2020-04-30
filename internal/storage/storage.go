package storage

import (
	"fmt"
	"sync"
)

var (
	worlds   map[string]World
	worldsMx sync.RWMutex
)

var Storage interface {
	Enum() ([]string, error)
	Load(id string) (World, error)
	Save(w World) error
}

func Load() (err error) {
	worldsMx.Lock()
	defer worldsMx.Unlock()

	worlds = map[string]World{}

	ids, err := Storage.Enum()
	if err == nil {
		for _, id := range ids {
			if world, err := Storage.Load(id); err == nil {
				world.normalise()
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
	if err = Storage.Save(w); err == nil {
		worlds[id] = w
	}
	return
}
