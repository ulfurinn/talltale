package editor

import (
	"encoding/json"
	"fmt"
	"log"
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
				r.Get("/", handle(createLocation))
				r.Patch("/{locationID}", handle(patchLocation))
			})
		})
	})

	return router
}

type wrappedHandler func(*http.Request) (resp interface{}, err error)

type renderable interface {
	render(http.ResponseWriter, *http.Request)
}

type notFoundError struct {
}

func (notFoundError) Error() string { return "entity not found" }
func (e notFoundError) render(rw http.ResponseWriter, req *http.Request) {
	render.Status(req, 404)
	render.JSON(rw, req, map[string]interface{}{"error": e.Error()})
}

func handle(f wrappedHandler) http.HandlerFunc {
	return http.HandlerFunc(func(rw http.ResponseWriter, req *http.Request) {
		var resp interface{}
		var err error
		defer func() {
			if rescued := recover(); rescued != nil {
				err = fmt.Errorf("fatal: %v", rescued)
			}
			if err == nil {
				render.JSON(rw, req, resp)
			} else if r, ok := err.(renderable); ok {
				r.render(rw, req)
			} else {
				render.Status(req, 500)
				render.JSON(rw, req, map[string]interface{}{"error": err.Error()})
			}
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

type createLocationRequest struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

type patchLocationRequest struct {
	Name        *string `json:"name"`
	Description *string `json:"description"`
}

func createLocation(req *http.Request) (response interface{}, err error) {
	dec := json.NewDecoder(req.Body)
	var r createLocationRequest
	if err = dec.Decode(&r); err != nil {
		return
	}
	log.Printf("creating location %v", r)

	storage.UpdateWorld(chi.URLParam(req, "worldID"), func(w *storage.World) {
		w.AddLocation(r.ID, storage.Location{
			Name: r.Name,
		})
	})

	response = true
	return
}

func patchLocation(req *http.Request) (response interface{}, err error) {
	dec := json.NewDecoder(req.Body)
	var r patchLocationRequest
	if err = dec.Decode(&r); err != nil {
		return
	}
	log.Printf("patching location")

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
