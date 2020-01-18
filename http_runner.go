package talltale

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/ulfurinn/talltale/internal/editor"
)

type runnerState int

const (
	RunnerStateLocation runnerState = iota
	RunnerStateEncounter
)

type HttpRunner struct {
	Game        Game
	Port        int
	AllowEditor bool
	state       runnerState
}

func (r *HttpRunner) Run() (err error) {
	fmt.Printf("talltale HTTP server: http://localhost:%d\n", r.Port)

	mux := http.NewServeMux()
	mux.Handle("/", http.FileServer(http.Dir("./build")))
	mux.HandleFunc("/scene", r.serveScene)
	mux.HandleFunc("/action", r.processAction)
	mux.HandleFunc("/resetGame", r.resetGame)

	if r.AllowEditor {
		mux.Handle("/editor/", http.StripPrefix("/editor", editor.Mux()))
	}

	s := http.Server{
		Addr:           fmt.Sprintf(":%d", r.Port),
		Handler:        mux,
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

	switch r.state {
	case RunnerStateLocation:
		err = r.locationAction(req)
	case RunnerStateEncounter:
		err = r.encounterAction(req)
	}

	return
}

func (r *HttpRunner) resetGame(rw http.ResponseWriter, rq *http.Request) {
	r.Game.Reset()
	r.state = RunnerStateLocation
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
	var encounter Encounter
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
	r.state = RunnerStateEncounter
	r.Game.Player.Encounter = encounter.ID
	return
}

func (r *HttpRunner) changeLocation(req ActionRequest) (err error) {
	return
}

func (r *HttpRunner) encounterAction(req ActionRequest) (err error) {
	var choice Choice
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
	r.state = RunnerStateLocation

	return
}

func (r *HttpRunner) displayableEncounters() (displayableEncounters []Encounter) {
	l := r.Game.Location()

	for _, e := range l.Encounters {
		if e.Displayable(r.Game) {
			displayableEncounters = append(displayableEncounters, e)
		}
	}
	return
}

func (r *HttpRunner) displayableChoices() (displayableChoices []Choice) {
	for _, c := range r.Game.Encounter().Choices {
		if c.Displayable(r.Game) {
			displayableChoices = append(displayableChoices, c)
		}
	}
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

	switch r.state {
	case RunnerStateLocation:
		scene["scene"] = map[string]interface{}{
			"name":        l.Name,
			"description": l.Description,
		}
		sceneEncounters := []map[string]interface{}{}
		for _, e := range r.displayableEncounters() {
			sceneEncounters = append(sceneEncounters, map[string]interface{}{
				"id":          e.ID,
				"name":        e.Name,
				"description": e.Description,
				"available":   e.Available(r.Game),
			})
		}
		scene["encounters"] = sceneEncounters

	case RunnerStateEncounter:
		e := r.Game.Encounter()
		scene["encounter"] = e.ID
		scene["scene"] = map[string]interface{}{
			"id":          e.ID,
			"name":        e.Name,
			"description": e.Description,
			"story":       e.Story,
		}

		sceneChoices := []map[string]interface{}{}
		for _, c := range r.displayableChoices() {
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
