package talltale

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"reflect"
	"sync"
	"time"

	"github.com/go-chi/chi"
	"github.com/go-chi/chi/middleware"
	"github.com/google/uuid"
	"github.com/ulfurinn/talltale/internal/editor"
	"github.com/ulfurinn/talltale/internal/runner"
	"github.com/ulfurinn/talltale/internal/storage"
)

type HttpRunner struct {
	Port        int
	AllowEditor bool
	sessions    map[string]*runner.Game
	sessionsMx  sync.RWMutex
}

func (r *HttpRunner) Run() (err error) {
	fmt.Printf("talltale HTTP server: http://localhost:%d\n", r.Port)

	router := chi.NewRouter()
	router.Use(
		middleware.RequestID,
		middleware.Logger,
		middleware.DefaultCompress,
		middleware.Recoverer,
		middleware.Timeout(30*time.Second),
	)
	router.Get("/*", http.FileServer(http.Dir("./build")).ServeHTTP)
	router.Get("/scene", handler(r.scene))
	router.Post("/action", handler(r.processAction))
	router.Post("/reset", handler(r.reset))

	if r.AllowEditor {
		router.Mount("/editor", editor.Mux())
	}

	r.sessions = map[string]*runner.Game{}

	s := http.Server{
		Addr:           fmt.Sprintf(":%d", r.Port),
		Handler:        router,
		ReadTimeout:    10 * time.Second,
		WriteTimeout:   10 * time.Second,
		MaxHeaderBytes: 1 << 20,
	}
	return s.ListenAndServe()
}

func validateHandler(t reflect.Type) {
	if t.Kind() != reflect.Func {
		panic(fmt.Errorf("handler: expected a function, got %v", t))
	}

	var resp *http.ResponseWriter
	var req *http.Request
	var err *error

	if t.NumIn() == 2 {
		if !t.In(0).Implements(reflect.TypeOf(resp).Elem()) {
			panic(fmt.Errorf("expected the second argument to be http.ResponseWriter, got %v", t))
		}

		if t.In(1) != reflect.TypeOf(req) {
			panic(fmt.Errorf("expected the third argument to be *http.Request, got %v", t))
		}

	} else if t.NumIn() == 3 {
		if !t.In(1).Implements(reflect.TypeOf(resp).Elem()) {
			panic(fmt.Errorf("expected the second argument to be http.ResponseWriter, got %v", t))
		}

		if t.In(2) != reflect.TypeOf(req) {
			panic(fmt.Errorf("expected the third argument to be *http.Request, got %v", t))
		}

	} else {
		panic(fmt.Errorf("expected the handler function to accept 2 or 3 arguments, got %v", t))
	}

	if t.NumOut() != 2 {
		panic(fmt.Errorf("expected the handler function to return 2 arguments, got %v", t))
	}

	if !t.Out(1).Implements(reflect.TypeOf(err).Elem()) {
		panic(fmt.Errorf("expected the second return argument to be error, got %v", t))
	}
}

func invokeHandler(ft reflect.Type, fv reflect.Value, rw http.ResponseWriter, req *http.Request) []reflect.Value {
	if ft.NumIn() == 3 {
		reqT := ft.In(0)
		value := reflect.New(reqT)
		if err := json.NewDecoder(req.Body).Decode(value.Interface()); err != nil {
			return []reflect.Value{reflect.ValueOf(nil), reflect.ValueOf(requestError{error: err})}
		}
		return fv.Call([]reflect.Value{value.Elem(), reflect.ValueOf(rw), reflect.ValueOf(req)})
	}
	return fv.Call([]reflect.Value{reflect.ValueOf(rw), reflect.ValueOf(req)})
}

func handler(f interface{}) http.HandlerFunc {
	t := reflect.TypeOf(f)
	fv := reflect.ValueOf(f)

	validateHandler(t)

	return func(rw http.ResponseWriter, req *http.Request) {
		respValues := invokeHandler(t, fv, rw, req)

		if err := respValues[1].Interface(); err != nil {
			if err, ok := err.(renderer); ok {
				err.render(rw)
				return
			}
			if err, ok := err.(error); ok {
				serverError{error: err}.render(rw)
				return
			}
			rw.WriteHeader(500)
			json.NewEncoder(rw).Encode(map[string]interface{}{"error": fmt.Sprintf("%v", err)})
			return
		}

		resp := respValues[0].Interface()
		rw.WriteHeader(200)
		json.NewEncoder(rw).Encode(resp)
	}
}

func (r *HttpRunner) scene(rw http.ResponseWriter, rq *http.Request) (resp map[string]interface{}, err error) {
	var game *runner.Game

	var cookie *http.Cookie
	if cookie, err = rq.Cookie(sessionCookie); err == nil {
		game, _ = r.getGame(cookie.Value)
	} else if err == http.ErrNoCookie {
		// just quietly accept
		err = nil
	}
	if game == nil {
		game = &runner.Game{}
	}
	resp = r.buildScene(game)
	return
}

const sessionCookie = "talltalesessid"

func (r *HttpRunner) getGame(sessid string) (game *runner.Game, err error) {
	var ok bool

	r.sessionsMx.RLock()
	game, ok = r.sessions[sessid]
	r.sessionsMx.RUnlock()
	if !ok {
		err = errors.New("no running game")
	}
	return
}

func (r *HttpRunner) setGame(game *runner.Game, sessid string) {
	r.sessionsMx.Lock()
	r.sessions[sessid] = game
	r.sessionsMx.Unlock()
}

func (r *HttpRunner) processAction(req runner.ActionRequest, rw http.ResponseWriter, rq *http.Request) (resp map[string]interface{}, err error) {

	var cookie *http.Cookie
	if cookie, err = rq.Cookie(sessionCookie); err == http.ErrNoCookie {
		err = errors.New("no running game")
		return
	}

	var game *runner.Game
	if game, err = r.getGame(cookie.Value); err != nil {
		return
	}

	if req.ChoiceType == "" || req.ChoiceID == "" {
		err = errors.New("choice type and id must be provided")
		return
	}

	switch game.State() {
	case runner.StateEmpty:
		err = errors.New("no game in progress")
	case runner.StateLocation:
		err = game.LocationAction(req)
	case runner.StateEncounter:
		err = game.EncounterAction(req)
	}

	r.setGame(game, cookie.Value)
	resp = r.buildScene(game)

	return
}

func (r *HttpRunner) reset(req struct {
	World string `json:"world"`
}, rw http.ResponseWriter, rq *http.Request) (resp map[string]interface{}, err error) {

	game := r.initGame(rw, rq)

	var storedWorld storage.World
	if storedWorld, err = storage.GetWorld(req.World); err != nil {
		return
	}
	world, _ := runner.LoadWorld(storedWorld)

	game.Reset(world)

	resp = r.buildScene(game)
	return
}

func (r *HttpRunner) initGame(rw http.ResponseWriter, req *http.Request) (game *runner.Game) {
	if cookie, err := req.Cookie(sessionCookie); err == nil {
		game, _ = r.getGame(cookie.Value)
		if game == nil {
			game = &runner.Game{}
			r.setGame(game, cookie.Value)
		}
		return
	}

	session := uuid.New().String()
	cookie := &http.Cookie{
		Name:     sessionCookie,
		Value:    session,
		HttpOnly: true,
		SameSite: http.SameSiteStrictMode,
	}
	http.SetCookie(rw, cookie)
	game = &runner.Game{}
	r.setGame(game, session)
	return
}

func (r *HttpRunner) buildScene(game *runner.Game) (scene map[string]interface{}) {
	scene = map[string]interface{}{}
	worlds := []storage.World{}
	for _, w := range storage.Worlds() {
		worlds = append(worlds, w.WithoutChildren())
	}
	scene["worlds"] = worlds

	if game.State() == runner.StateEmpty {
		return
	}

	l := game.Location()

	scene["world"] = map[string]interface{}{
		"title": game.World.Title,
	}
	scene["encounters"] = []interface{}{}
	scene["locations"] = []interface{}{}
	scene["choices"] = []interface{}{}
	scene["scene"] = nil
	scene["location"] = l.ID
	scene["encounter"] = nil
	scene["inventory"] = game.Player.Inventory

	switch game.State() {
	case runner.StateLocation:
		scene["scene"] = map[string]interface{}{
			"name":        l.Name,
			"description": l.Description,
		}
		sceneEncounters := []map[string]interface{}{}
		for _, e := range game.DisplayableEncounters() {
			sceneEncounters = append(sceneEncounters, map[string]interface{}{
				"id":          e.ID,
				"name":        e.Name,
				"description": e.Description,
				"available":   e.Available(game.Player),
			})
		}
		scene["encounters"] = sceneEncounters

	case runner.StateEncounter:
		e := game.Encounter()
		scene["encounter"] = e.ID
		scene["scene"] = map[string]interface{}{
			"id":          e.ID,
			"name":        e.Name,
			"description": e.Description,
			"story":       e.Story,
		}

		sceneChoices := []map[string]interface{}{}
		for _, c := range game.DisplayableChoices() {
			sceneChoices = append(sceneChoices, map[string]interface{}{
				"id":          c.ID,
				"name":        c.Name,
				"description": c.Description,
				"available":   c.Available(game.Player),
			})
		}
		scene["choices"] = sceneChoices

	}

	return scene
}
