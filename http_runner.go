package talltale

import (
	"fmt"
	"net/http"
	"time"

	"github.com/yosssi/ace"
)

type HttpRunner struct {
	Game Game
}

func (r *HttpRunner) Run() (err error) {
	fmt.Println("talltale HTTP server")

	mux := http.NewServeMux()
	mux.Handle("/", http.FileServer(http.Dir("./public")))
	mux.HandleFunc("/index", r.index)
	mux.HandleFunc("/game", r.render)
	mux.HandleFunc("/action", r.action)

	s := http.Server{
		Addr:           ":8080",
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

	if r.Game.Player.Encounter == "" {
		template = "location"
	} else {
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
		"World":  r.Game.World,
		"Player": r.Game.Player,
		"Scene":  r.buildScene(),
	}); err != nil {
		http.Error(rw, err.Error(), http.StatusInternalServerError)
		return
	}
}
func (r *HttpRunner) action(rw http.ResponseWriter, req *http.Request) {

}

func (r *HttpRunner) buildScene() map[string]interface{} {
	scene := map[string]interface{}{}

	l := r.Game.Location()

	var availableEncounters []Encounter
	var gameOver bool

	for _, e := range l.Encounters {
		if e.Displayable(r.Game) {
			availableEncounters = append(availableEncounters, e)
		}
	}

	if len(availableEncounters) == 0 {
		gameOver = true
	}

	sceneEncounters := []map[string]interface{}{}
	for _, e := range availableEncounters {
		sceneEncounters = append(sceneEncounters, map[string]interface{}{
			"ID":          e.ID,
			"Name":        e.Name,
			"Description": e.Description,
		})
	}

	scene["Location"] = map[string]interface{}{
		"Name":        l.Name,
		"Description": l.Description,
	}
	scene["GameOver"] = gameOver
	scene["Encounters"] = sceneEncounters

	return scene
}
