package talltale_test

import (
	"errors"
	"reflect"
	"testing"

	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
	"github.com/onsi/gomega/format"
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

func pstring(s string) *string { return &s }
func pint(i int) *int          { return &i }

type PointToMatcher struct {
	value interface{}
}

func (m PointToMatcher) FailureMessage(v interface{}) string {
	return format.Message(v, "to be a pointer to", m.value)
}

func (m PointToMatcher) NegatedFailureMessage(v interface{}) string {
	return format.Message(v, "not to be a pointer to", m.value)
}

func (m PointToMatcher) Match(v interface{}) (bool, error) {
	rv := reflect.ValueOf(v)
	if rv.Kind() != reflect.Ptr {
		return false, nil
	}
	return reflect.DeepEqual(rv.Elem().Interface(), m.value), nil
}

func PointTo(v interface{}) PointToMatcher {
	return PointToMatcher{value: v}
}

func testWorld() (w storage.World) {
	w.ID = "test"
	w.Global.Title = "Test World"
	w.Locations = map[string]storage.Location{
		"start": {
			Name:        "Start",
			Description: "It all began here.",
			Encounters: []storage.Encounter{{
				ID:          "encounter-1",
				Name:        "Encounter 1",
				Description: "This is an encounter",
				Story:       "This is what happened when you opened the door.",
				Conditions: map[string]storage.Condition{
					"strong": {StatCondition: storage.StatConditionSet{
						"strength": {
							Min: pint(5),
						},
					}},
				},
				Choices: []storage.Choice{},
			}},
		},
	}
	w.Stats = map[string]storage.Stat{}
	w.PlayerSeed.Location = "start"
	w.PlayerSeed.Stats = map[string]int{}
	return
}
