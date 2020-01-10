package talltale

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"time"

	"github.com/yosssi/ace"
)

type runnerState int

const (
	RunnerStateLocation runnerState = iota
	RunnerStateEncounter
)

type HttpRunner struct {
	Game  Game
	Port  int
	state runnerState
}

func (r *HttpRunner) Run() (err error) {
	fmt.Printf("talltale HTTP server: http://localhost:%d\n", r.Port)

	mux := http.NewServeMux()
	mux.Handle("/", http.FileServer(http.Dir("./public")))
	mux.HandleFunc("/index", r.index)
	mux.HandleFunc("/game", r.render)
	mux.HandleFunc("/action", r.action)

	s := http.Server{
		Addr:           fmt.Sprintf(":%d", r.Port),
		Handler:        mux,
		ReadTimeout:    10 * time.Second,
		WriteTimeout:   10 * time.Second,
		MaxHeaderBytes: 1 << 20,
	}
	return s.ListenAndServe()
}

func (r *HttpRunner) index(rw http.ResponseWriter, req *http.Request) {
	tpl, err := ace.Load("layout", "index", &ace.Options{
		BaseDir: "./worlds/" + r.Game.ID + "/templates",
	})
	if err != nil {
		http.Error(rw, err.Error(), http.StatusInternalServerError)
		return
	}
	if err := tpl.Execute(rw, map[string]interface{}{"World": r.Game.World}); err != nil {
		http.Error(rw, err.Error(), http.StatusInternalServerError)
		return
	}
}
func (r *HttpRunner) render(rw http.ResponseWriter, req *http.Request) {
	var template string

	switch r.state {
	case RunnerStateLocation:
		template = "location"
	case RunnerStateEncounter:
		template = "encounter"
	}

	tpl, err := ace.Load("layout", template, &ace.Options{
		BaseDir: "./worlds/" + r.Game.ID + "/templates",
	})
	if err != nil {
		http.Error(rw, err.Error(), http.StatusInternalServerError)
		return
	}
	if err := tpl.Execute(rw, map[string]interface{}{
		"World":     r.Game.World,
		"Player":    r.Game.Player,
		"Scene":     r.buildScene(),
		"Inventory": r.Game.Player.Inventory,
	}); err != nil {
		http.Error(rw, err.Error(), http.StatusInternalServerError)
		return
	}
}

type ActionRequest struct {
	Encounter string `json:"encounter"`
	Location  string `json:"location"`
	Choice    string `json:"choice"`
}

type ActionResponse struct {
	Error     string        `json:"error,omitempty"`
	Effects   []interface{} `json:"effects,omitempty"`
	Location  string        `json:"location,omitempty"`
	Encounter string        `json:"encounter,omitempty"`
}

func (r *HttpRunner) action(rw http.ResponseWriter, rq *http.Request) {
	var req ActionRequest
	var resp ActionResponse
	var err error
	defer func() {
		rw.Header().Set("content-type", "application/json")
		if err != nil {
			resp.Error = err.Error()
		}
		encoder := json.NewEncoder(rw)
		encoder.Encode(resp)
	}()
	decoder := json.NewDecoder(rq.Body)
	if err = decoder.Decode(&req); err != nil {
		return
	}

	switch r.state {
	case RunnerStateLocation:
		resp, err = r.locationAction(req)
	case RunnerStateEncounter:
		resp, err = r.encounterAction(req)
	}

	return
}

func (r *HttpRunner) locationAction(req ActionRequest) (resp ActionResponse, err error) {
	if req.Encounter != "" {
		resp, err = r.chooseEncounter(req)
	} else if req.Location != "" {
		resp, err = r.changeLocation(req)
	} else {
		err = errors.New("either an encounter or a location must be provided")
	}
	return
}

func (r *HttpRunner) chooseEncounter(req ActionRequest) (resp ActionResponse, err error) {
	var encounter Encounter
	var found bool
	for _, encounter = range r.Game.Location().Encounters {
		if encounter.ID == req.Encounter {
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

	resp.Location = r.Game.Location().ID
	resp.Encounter = r.Game.Encounter().ID
	return
}

func (r *HttpRunner) changeLocation(req ActionRequest) (resp ActionResponse, err error) {
	return
}

func (r *HttpRunner) encounterAction(req ActionRequest) (resp ActionResponse, err error) {
	if req.Choice != "" {
		var choice Choice
		var found bool

		for _, choice = range r.Game.Encounter().Choices {
			if choice.ID == req.Choice {
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

		resp.Location = r.Game.Location().ID
		resp.Encounter = r.Game.Encounter().ID

		return

	} else {
		err = errors.New("a choice must be provided")
		return
	}
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
	scene := map[string]interface{}{}

	l := r.Game.Location()
	scene["Location"] = map[string]interface{}{
		"Name":        l.Name,
		"Description": l.Description,
	}

	switch r.state {
	case RunnerStateLocation:
		sceneEncounters := []map[string]interface{}{}
		for _, e := range r.displayableEncounters() {
			sceneEncounters = append(sceneEncounters, map[string]interface{}{
				"ID":          e.ID,
				"Name":        e.Name,
				"Description": e.Description,
				"Available":   e.Available(r.Game),
			})
		}
		scene["Encounters"] = sceneEncounters

	case RunnerStateEncounter:
		e := r.Game.Encounter()
		scene["Encounter"] = map[string]interface{}{
			"ID":          e.ID,
			"Name":        e.Name,
			"Description": e.Description,
			"Story":       e.Story,
		}

		sceneChoices := []map[string]interface{}{}
		for _, c := range r.displayableChoices() {
			sceneChoices = append(sceneChoices, map[string]interface{}{
				"ID":          c.ID,
				"Name":        c.Name,
				"Description": c.Description,
				"Available":   c.Available(r.Game),
			})
		}
		scene["Choices"] = sceneChoices

	}

	return scene
}
