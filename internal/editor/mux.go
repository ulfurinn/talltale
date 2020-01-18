package editor

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/go-chi/chi"
	"github.com/go-chi/chi/middleware"
)

type editor struct {
}

func Mux() http.Handler {
	router := chi.NewRouter()
	router.Use(middleware.Recoverer)

	router.Get("/worlds", handle(getWorlds))
	return logger(router)
}

func logger(handler http.Handler) http.Handler {
	return http.HandlerFunc(func(rw http.ResponseWriter, req *http.Request) {
		log.Printf("%v | %s %s", time.Now(), req.Method, req.URL.String())
		handler.ServeHTTP(rw, req)
	})
}

type wrappedHandler func(req *http.Request) (resp interface{}, err error)

func handle(f wrappedHandler) http.HandlerFunc {
	return http.HandlerFunc(func(rw http.ResponseWriter, req *http.Request) {
		var resp interface{}
		var err error
		defer func() {
			if rescued := recover(); rescued != nil {
				err = fmt.Errorf("fatal: %v", rescued)
			}
			encoder := json.NewEncoder(rw)
			if err == nil {
				rw.WriteHeader(200)
				encoder.Encode(resp)
			} else {
				rw.WriteHeader(500)
				encoder.Encode(map[string]interface{}{"error": err.Error()})
			}
		}()
		rw.Header().Set("Content-Type", "application/json")
		resp, err = f(req)
	})
}

func getWorlds(*http.Request) (interface{}, error) {
	return []interface{}{}, nil
}
