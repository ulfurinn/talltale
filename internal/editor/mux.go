package editor

import (
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
	worlds, err := storage.Worlds()
	for i := range worlds {
		worlds[i].StripChildren()
	}
	return worlds, err
}

func getWorld(req *http.Request, headers http.Header) (interface{}, error) {
	world, err := storage.LoadWorld(chi.URLParam(req, "worldID"))
	return world, err
}
