package talltale_test

import (
	"errors"
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/ulfurinn/talltale/internal/storage"
)

func TestTalltale(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Talltale Suite")
}

type testStorer struct {
	worlds map[string]storage.World
}

func (s *testStorer) Enum() ([]string, error) {
	keys := []string{}
	for k := range s.worlds {
		keys = append(keys, k)
	}
	return keys, nil
}

func (s *testStorer) Load(id string) (storage.World, error) {
	if w, ok := s.worlds[id]; ok {
		return w, nil
	}
	return storage.World{}, errors.New("would not found")
}

func (s *testStorer) Save(w storage.World) error {
	s.worlds[w.ID] = w
	return nil
}

func testWorld() (w storage.World) {
	w.ID = "test"
	w.Global.Title = "Test World"
	w.Locations = map[string]storage.Location{
		"start": {
			Name:        "Start",
			Description: "It all began here.",
		},
	}
	w.Stats = map[string]storage.Stat{}
	w.PlayerSeed.Location = "start"
	w.PlayerSeed.Stats = map[string]int{}
	return
}
