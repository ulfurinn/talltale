package editor

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi"
	"github.com/ulfurinn/talltale/internal/storage"
)

type CreateConditionRequest struct {
	ID   string                   `json:"id"`
	Stat map[string]StatCondition `json:"stat,omitempty"`
}

type StatCondition struct {
	Min  *int `yaml:"min" json:"min"`
	Max  *int `yaml:"max" json:"max"`
	Hide bool `yaml:"hide" json:"hide"`
}

func createCondition(req *http.Request) (response interface{}, err error) {
	dec := json.NewDecoder(req.Body)
	var r CreateConditionRequest
	if err = dec.Decode(&r); err != nil {
		return
	}

	worldID := chi.URLParam(req, "worldID")
	locationID := chi.URLParam(req, "locationID")
	encounterID := chi.URLParam(req, "encounterID")

	storage.UpdateWorld(worldID, func(w *storage.World) {
		loc := w.Locations[locationID]
		for _, enc := range loc.Encounters {
			if enc.ID == encounterID {
				if _, found := enc.Conditions[r.ID]; found {
					err = alreadyExists{}
					return
				}
				cond := storage.Condition{}
				cond.StatCondition = storage.StatConditionSet{}
				for k, v := range r.Stat {
					stat := storage.StatCondition{}
					stat.Min = v.Min
					stat.Max = v.Max
					stat.Hide = v.Hide
					cond.StatCondition[k] = stat
				}
				enc.Conditions[r.ID] = cond
				return
			}
		}
		err = notFoundError{}
	})

	return
}
