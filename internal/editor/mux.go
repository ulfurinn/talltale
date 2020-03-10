package editor

import (
	"encoding/json"
	"errors"
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
			r.Post("/locations", handle(createLocation))
		})
	})

	return router
}

type wrappedHandler func(*http.Request, http.Header) (resp interface{}, err error)

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
			} else {
				render.Status(req, 500)
				render.JSON(rw, req, map[string]interface{}{"error": err.Error()})
			}
		}()
		resp, err = f(req, rw.Header())
	})
}

func getWorlds(req *http.Request, headers http.Header) (interface{}, error) {
	worlds := []storage.World{}
	for _, world := range storage.Worlds() {
		world.StripChildren()
		worlds = append(worlds, world)
	}
	return worlds, nil
}

func getWorld(req *http.Request, headers http.Header) (interface{}, error) {
	return storage.GetWorld(chi.URLParam(req, "worldID"))
}

type createLocationRequest struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

func createLocation(req *http.Request, headers http.Header) (response interface{}, err error) {
	if req.Body == nil {
		err = errors.New("missing request body")
		return
	}
	defer req.Body.Close()

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
