package talltale

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
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
	sessions    map[string]runner.Game
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
	router.Get("/", http.FileServer(http.Dir("./build")).ServeHTTP)
	router.Get("/scene", r.scene)
	router.Post("/action", r.processAction)
	router.Post("/reset", r.reset)

	if r.AllowEditor {
		router.Mount("/editor", editor.Mux())
	}

	r.sessions = map[string]runner.Game{}

	s := http.Server{
		Addr:           fmt.Sprintf(":%d", r.Port),
		Handler:        router,
		ReadTimeout:    10 * time.Second,
		WriteTimeout:   10 * time.Second,
		MaxHeaderBytes: 1 << 20,
	}
	return s.ListenAndServe()
}

func (r *HttpRunner) scene(rw http.ResponseWriter, rq *http.Request) {
	var resp map[string]interface{}
	var err error
	defer func() {
		rw.Header().Set("content-type", "application/json")
		if err != nil {
			resp = map[string]interface{}{"error": err.Error()}
		}
		encoder := json.NewEncoder(rw)
		encoder.Encode(resp)
	}()

	var game runner.Game

	var cookie *http.Cookie
	if cookie, err = rq.Cookie(sessionCookie); err == nil {
		game, _ = r.getGame(cookie.Value)
	} else if err == http.ErrNoCookie {
		// just quietly accept
		err = nil
	}
	resp = r.buildScene(game)
}

const sessionCookie = "talltalesessid"

func (r *HttpRunner) getGame(sessid string) (game runner.Game, err error) {
	var ok bool

	r.sessionsMx.RLock()
	game, ok = r.sessions[sessid]
	r.sessionsMx.RUnlock()
	if !ok {
		err = errors.New("no running game")
	}
	return
}

func (r *HttpRunner) setGame(game runner.Game, sessid string) {
	r.sessionsMx.Lock()
	r.sessions[sessid] = game
	r.sessionsMx.Unlock()
}

func (r *HttpRunner) processAction(rw http.ResponseWriter, rq *http.Request) {
	var req runner.ActionRequest
	var resp map[string]interface{}
	var err error
	defer func() {
		rw.Header().Set("content-type", "application/json")

		if err != nil {
			resp = map[string]interface{}{"error": err.Error()}
		}
		encoder := json.NewEncoder(rw)
		encoder.Encode(resp)
	}()

	var cookie *http.Cookie
	if cookie, err = rq.Cookie(sessionCookie); err == http.ErrNoCookie {
		err = errors.New("no running game")
		return
	}

	var game runner.Game
	if game, err = r.getGame(cookie.Value); err != nil {
		return
	}

	decoder := json.NewDecoder(rq.Body)
	if err = decoder.Decode(&req); err != nil {
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

func (r *HttpRunner) reset(rw http.ResponseWriter, rq *http.Request) {
	var req struct {
		World string `json:"looking-glass`
	}
	var resp map[string]interface{}
	var err error
	defer func() {
		rw.Header().Set("content-type", "application/json")
		if err != nil {
			resp = map[string]interface{}{"error": err.Error()}
		}
		encoder := json.NewEncoder(rw)
		encoder.Encode(resp)
	}()

	decoder := json.NewDecoder(rq.Body)
	if err = decoder.Decode(&req); err != nil {
		return
	}

	var game runner.Game
	var cookie *http.Cookie
	var sessid string

	if cookie, err = rq.Cookie(sessionCookie); err == nil {
		sessid = cookie.Value
		game, _ = r.getGame(sessid)
	} else if err == http.ErrNoCookie {
		sessid = uuid.New().String()
		cookie = &http.Cookie{
			Name:     sessionCookie,
			Value:    sessid,
			HttpOnly: true,
			SameSite: http.SameSiteStrictMode,
		}
		http.SetCookie(rw, cookie)
	}

	var storedWorld storage.World
	if storedWorld, err = storage.GetWorld(req.World); err != nil {
		return
	}
	world := storedWorld.Parse()

	game.Reset(world)

	r.setGame(game, cookie.Value)

	resp = r.buildScene(game)
}

func (r *HttpRunner) buildScene(game runner.Game) (scene map[string]interface{}) {
	scene = map[string]interface{}{}
	worlds := []storage.World{}
	for _, w := range storage.Worlds() {
		w.StripChildren()
		worlds = append(worlds, w)
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
				"available":   e.Available(&game),
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
				"available":   c.Available(&game),
			})
		}
		scene["choices"] = sceneChoices

	}

	return scene
}
