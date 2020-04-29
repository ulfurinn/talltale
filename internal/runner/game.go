package runner

import (
	"errors"
	"fmt"
)

type State int

const (
	StateEmpty State = iota
	StateLocation
	StateEncounter
)

type Game struct {
	state  State
	World  World
	Player Player
}

type ActionRequest struct {
	ChoiceType string `json:"choiceType"`
	ChoiceID   string `json:"choiceID"`
}

func (g *Game) Location() Location {
	return g.World.Locations[g.Player.Location]
}

func (g *Game) Encounter() Encounter {
	if g.Player.Encounter == "" {
		return Encounter{}
	}
	for _, e := range g.Location().Encounters {
		if e.ID == g.Player.Encounter {
			return e
		}
	}
	return Encounter{}
}

func (g *Game) State() State {
	return g.state
}

func (g *Game) Reset(world World) {
	g.state = StateLocation
	g.World = world
	g.Player = Player{}
	g.Player.Location = world.TabulaRasa.Location
	g.Player.Inventory = map[string]int{}
	for k, v := range world.TabulaRasa.Inventory {
		g.Player.Inventory[k] = v
	}
}

func (g *Game) DisplayableEncounters() (displayableEncounters []Encounter) {
	l := g.Location()

	for _, e := range l.Encounters {
		if e.Displayable(g.Player) {
			displayableEncounters = append(displayableEncounters, e)
		}
	}
	return
}

func (g *Game) DisplayableChoices() (displayableChoices []Choice) {
	for _, c := range g.Encounter().Choices {
		if c.Displayable(g.Player) {
			displayableChoices = append(displayableChoices, c)
		}
	}
	return
}

func (g *Game) LocationAction(req ActionRequest) (err error) {
	switch req.ChoiceType {
	case "encounter":
		err = g.chooseEncounter(req)
	case "location":
		err = g.changeLocation(req)
	default:
		err = errors.New("either an encounter or a location must be provided")
	}
	return
}

func (g *Game) chooseEncounter(req ActionRequest) (err error) {
	var encounter Encounter
	var found bool
	for _, encounter = range g.Location().Encounters {
		if encounter.ID == req.ChoiceID {
			found = true
			break
		}
	}
	if !found {
		err = errors.New("no such encounter in this location")
		return
	}
	if !encounter.Displayable(g.Player) {
		err = errors.New("the selected action is not displayable")
		return
	}
	g.state = StateEncounter
	g.Player.Encounter = encounter.ID
	return
}

func (g *Game) changeLocation(req ActionRequest) (err error) {
	return
}

func (g *Game) EncounterAction(req ActionRequest) (err error) {
	var choice Choice
	var found bool

	for _, choice = range g.Encounter().Choices {
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
		if e.Success(g.Player) {
			fmt.Println("You are successful.")
			if e.Pass != nil {
				e.Pass(&g.Player)
			}
		} else {
			fmt.Println("You failed.")
			if e.Fail != nil {
				e.Fail(&g.Player)
			}
		}
	}
	g.state = StateLocation
	g.Player.Encounter = ""

	return
}
