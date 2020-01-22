package talltale

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/go-chi/chi"
	"github.com/go-chi/chi/middleware"
	"github.com/ulfurinn/talltale/internal/editor"
	"github.com/ulfurinn/talltale/internal/runner"
)

type HttpRunner struct {
	Game        *runner.Game
	Port        int
	AllowEditor bool
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
	router.Get("/scene", r.serveScene)
	router.Post("/action", r.processAction)
	router.Post("/resetGame", r.resetGame)

	if r.AllowEditor {
		router.Mount("/editor", editor.Mux())
	}

	s := http.Server{
		Addr:           fmt.Sprintf(":%d", r.Port),
		Handler:        router,
		ReadTimeout:    10 * time.Second,
		WriteTimeout:   10 * time.Second,
		MaxHeaderBytes: 1 << 20,
	}
	return s.ListenAndServe()
}

func (r *HttpRunner) serveScene(rw http.ResponseWriter, rq *http.Request) {
	rw.Header().Set("content-type", "application/json")
	encoder := json.NewEncoder(rw)
	encoder.Encode(r.buildScene())
}

type ActionRequest struct {
	ChoiceType string `json:"choiceType"`
	ChoiceID   string `json:"choiceID"`
}

func (r *HttpRunner) processAction(rw http.ResponseWriter, rq *http.Request) {
	var req ActionRequest
	var resp map[string]interface{}
	var err error
	defer func() {
		rw.Header().Set("content-type", "application/json")
		resp = r.buildScene()
		if err != nil {
			resp["error"] = err.Error()
		}
		encoder := json.NewEncoder(rw)
		encoder.Encode(resp)
	}()
	decoder := json.NewDecoder(rq.Body)
	if err = decoder.Decode(&req); err != nil {
		return
	}

	if req.ChoiceType == "" || req.ChoiceID == "" {
		err = errors.New("choice type and id must be provided")
		return
	}

	switch r.Game.State() {
	case runner.StateLocation:
		err = r.locationAction(req)
	case runner.StateEncounter:
		err = r.encounterAction(req)
	}

	return
}

func (r *HttpRunner) resetGame(rw http.ResponseWriter, rq *http.Request) {
	r.Game.Reset()
	rw.Header().Set("content-type", "application/json")
	encoder := json.NewEncoder(rw)
	encoder.Encode(r.buildScene())
}

func (r *HttpRunner) locationAction(req ActionRequest) (err error) {
	switch req.ChoiceType {
	case "encounter":
		err = r.chooseEncounter(req)
	case "location":
		err = r.changeLocation(req)
	default:
		err = errors.New("either an encounter or a location must be provided")
	}
	return
}

func (r *HttpRunner) chooseEncounter(req ActionRequest) (err error) {
	var encounter runner.Encounter
	var found bool
	for _, encounter = range r.Game.Location().Encounters {
		if encounter.ID == req.ChoiceID {
			found = true
			break
		}
	}
	if !found {
		err = errors.New("no such encounter in this location")
		return
	}
	if !encounter.Displayable(r.Game) {
		err = errors.New("the selected action is not displayable")
		return
	}
	r.Game.Player.Encounter = encounter.ID
	return
}

func (r *HttpRunner) changeLocation(req ActionRequest) (err error) {
	return
}

func (r *HttpRunner) encounterAction(req ActionRequest) (err error) {
	var choice runner.Choice
	var found bool

	for _, choice = range r.Game.Encounter().Choices {
		if choice.ID == req.ChoiceID {
			found = true
			break
		}
	}
	if !found {
		err = errors.New("no such choice in this encounter")
		return
	}

	for _, e := range choice.Effects {
		if e.Success(r.Game.Player) {
			fmt.Println("You are successful.")
			if e.Pass != nil {
				e.Pass(&r.Game.Player)
			}
		} else {
			fmt.Println("You failed.")
			if e.Fail != nil {
				e.Fail(&r.Game.Player)
			}
		}
	}
	r.Game.Player.Encounter = ""

	return
}

func (r *HttpRunner) buildScene() map[string]interface{} {
	l := r.Game.Location()
	scene := map[string]interface{}{
		"world": map[string]interface{}{
			"title": r.Game.World.Title,
		},
		"encounters": []interface{}{},
		"locations":  []interface{}{},
		"choices":    []interface{}{},
		"scene":      nil,
		"location":   l.ID,
		"encounter":  nil,
	}

	switch r.Game.State() {
	case runner.StateLocation:
		scene["scene"] = map[string]interface{}{
			"name":        l.Name,
			"description": l.Description,
		}
		sceneEncounters := []map[string]interface{}{}
		for _, e := range r.Game.DisplayableEncounters() {
			sceneEncounters = append(sceneEncounters, map[string]interface{}{
				"id":          e.ID,
				"name":        e.Name,
				"description": e.Description,
				"available":   e.Available(r.Game),
			})
		}
		scene["encounters"] = sceneEncounters

	case runner.StateEncounter:
		e := r.Game.Encounter()
		scene["encounter"] = e.ID
		scene["scene"] = map[string]interface{}{
			"id":          e.ID,
			"name":        e.Name,
			"description": e.Description,
			"story":       e.Story,
		}

		sceneChoices := []map[string]interface{}{}
		for _, c := range r.Game.DisplayableChoices() {
			sceneChoices = append(sceneChoices, map[string]interface{}{
				"id":          c.ID,
				"name":        c.Name,
				"description": c.Description,
				"available":   c.Available(r.Game),
			})
		}
		scene["choices"] = sceneChoices

	}

	return scene
}
