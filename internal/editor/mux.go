package editor

import (
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/go-chi/chi"
	"github.com/go-chi/render"
	"github.com/ulfurinn/talltale/internal/storage"
)

type editor struct {
}

func Mux() http.Handler {
	router := chi.NewRouter()

	router.Route("/worlds", func(r chi.Router) {
		r.Get("/", handle(getWorlds))
		r.Route("/{worldID}", func(r chi.Router) {
			r.Get("/", handle(getWorld))
			r.Route("/locations", func(r chi.Router) {
				r.Post("/", handle(createLocation))
				r.Route("/{locationID}", func(r chi.Router) {
					r.Patch("/", handle(patchLocation))
					r.Route("/encounters", func(r chi.Router) {
						r.Post("/", handle(createEncounter))
						r.Route("/{encounterID}", func(r chi.Router) {
							r.Route("/conditions", func(r chi.Router) {
								r.Post("/", handle(createCondition))
							})
						})
					})
				})
			})
		})
	})

	return router
}

type ErrorResponse struct {
	Error string `json:"error"`
}

type wrappedHandler func(*http.Request) (resp interface{}, err error)

type renderable interface {
	render(http.ResponseWriter, *http.Request)
}

type notFoundError struct {
}

func (notFoundError) Error() string { return "entity not found" }
func (e notFoundError) render(rw http.ResponseWriter, req *http.Request) {
	render.Status(req, http.StatusNotFound)
	render.JSON(rw, req, ErrorResponse{Error: e.Error()})
}

type alreadyExists struct{}

func (alreadyExists) Error() string { return "entity already exists" }
func (e alreadyExists) render(rw http.ResponseWriter, req *http.Request) {
	render.Status(req, http.StatusConflict)
	render.JSON(rw, req, ErrorResponse{Error: e.Error()})
}

func renderBody(resp interface{}, err error, rw http.ResponseWriter, req *http.Request) {
	if err == nil {
		switch req.Method {
		case http.MethodGet:
			render.Status(req, http.StatusOK)
		case http.MethodPost:
			render.Status(req, http.StatusCreated)
		default:
			render.Status(req, http.StatusOK)
		}
		render.JSON(rw, req, resp)
	} else {
		renderError(err, rw, req)
	}
}

func renderError(err error, rw http.ResponseWriter, req *http.Request) {
	if r, ok := err.(renderable); ok {
		r.render(rw, req)
	} else {
		render.Status(req, http.StatusInternalServerError)
		render.JSON(rw, req, ErrorResponse{Error: err.Error()})
	}
}

func handle(f wrappedHandler) http.HandlerFunc {
	return http.HandlerFunc(func(rw http.ResponseWriter, req *http.Request) {
		var resp interface{}
		var err error
		defer func() {
			if rescued := recover(); rescued != nil {
				err = fmt.Errorf("fatal: %v", rescued)
			}
			renderBody(resp, err, rw, req)
		}()
		if req.Method != "GET" {
			if req.Body == nil {
				err = fmt.Errorf("%s requests require a body", req.Method)
				return
			}
			defer req.Body.Close()
		}
		resp, err = f(req)
	})
}

func getWorlds(req *http.Request) (interface{}, error) {
	worlds := []storage.World{}
	for _, world := range storage.Worlds() {
		worlds = append(worlds, world.WithoutChildren())
	}
	return worlds, nil
}

func getWorld(req *http.Request) (interface{}, error) {
	return storage.GetWorld(chi.URLParam(req, "worldID"))
}

type CreateLocationRequest struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

type PatchLocationRequest struct {
	Name        *string `json:"name"`
	Description *string `json:"description"`
}

type CreateEncounterRequest struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Story       string `json:"story"`
}

func createLocation(req *http.Request) (response interface{}, err error) {
	dec := json.NewDecoder(req.Body)
	var r CreateLocationRequest
	if err = dec.Decode(&r); err != nil {
		return
	}

	storage.UpdateWorld(chi.URLParam(req, "worldID"), func(w *storage.World) {
		if _, exists := w.Locations[r.ID]; !exists {
			w.AddLocation(r.ID, storage.Location{
				Name:        r.Name,
				Description: r.Description,
			})
			response = true
		} else {
			err = alreadyExists{}
		}
	})

	return
}

func patchLocation(req *http.Request) (response interface{}, err error) {
	dec := json.NewDecoder(req.Body)
	var r PatchLocationRequest
	if err = dec.Decode(&r); err != nil {
		return
	}

	var l storage.Location
	var ok bool

	storage.UpdateWorld(chi.URLParam(req, "worldID"), func(w *storage.World) {
		id := chi.URLParam(req, "locationID")
		if l, ok = w.Locations[id]; ok {
			if r.Name != nil {
				l.Name = *r.Name
			}
			if r.Description != nil {
				l.Description = *r.Description
			}
			w.Locations[id] = l
		}
	})

	if ok {
		response = l
	} else {
		err = notFoundError{}
	}
	return
}

func createEncounter(req *http.Request) (response interface{}, err error) {
	dec := json.NewDecoder(req.Body)
	var r CreateEncounterRequest
	if err = dec.Decode(&r); err != nil {
		return
	}

	storage.UpdateWorld(chi.URLParam(req, "worldID"), func(w *storage.World) {
		id := chi.URLParam(req, "locationID")
		loc, found := w.Locations[id]
		if !found {
			err = notFoundError{}
			return
		}

		found = false
		for _, e := range loc.Encounters {
			if e.ID == r.ID {
				found = true
				break
			}
		}
		if found {
			err = alreadyExists{}
			return
		}
		encounter := storage.Encounter{
			ID:          r.ID,
			Name:        r.Name,
			Description: r.Description,
			Story:       r.Story,
			Conditions:  map[string]storage.Condition{},
			Choices:     []storage.Choice{},
		}
		loc.Encounters = append(loc.Encounters, encounter)
		w.Locations[id] = loc
		response = true
	})

	return
}
