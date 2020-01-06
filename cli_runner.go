package talltale

import "fmt"

type Runner struct {
	Game Game
}

func (r *Runner) Run() (err error) {
	for {
		fmt.Println("========")
		r.Scenery()

		enc, gameOver := r.PresentEncounters()
		if gameOver {
			break
		}

		fmt.Printf(">> %s\n>> %s\n", enc.Name, enc.Story)

		choice, empty := r.PresentChoices(enc)
		if empty {
			// must pick another encounter
			fmt.Println("There is nothing for you here. Try something else.")
			continue
		}
		fmt.Printf(">> %s\n>> %s\n", choice.Name, choice.Story)

		r.EnactChoice(choice)
	}
	fmt.Println("The End")
	return
}

func (r *Runner) Scenery() {
	l := r.Game.Location()
	fmt.Println(l.Name)
	fmt.Println(l.Description)
}

func (r *Runner) PresentEncounters() (encounter Encounter, gameOver bool) {
	var availableEncounters []Encounter

	l := r.Game.Location()
	for _, e := range l.Encounters {
		if e.Displayable(r.Game) {
			availableEncounters = append(availableEncounters, e)
		}
	}

	if len(availableEncounters) == 0 {
		gameOver = true
		return
	}

	for i, e := range availableEncounters {
		fmt.Printf("(%d) %s: %s\n", i+1, e.Name, e.Description)
	}

	var i int
	for {
		if _, err := fmt.Scan(&i); err == nil {
			if i >= 1 && i <= len(availableEncounters) && availableEncounters[i-1].Available(r.Game) {
				encounter = availableEncounters[i-1]
				return
			}
		}
	}
}

func (r *Runner) PresentChoices(enc Encounter) (choice Choice, empty bool) {
	var availableChoices []Choice

	for _, c := range enc.Choices {
		if c.Displayable(r.Game) {
			availableChoices = append(availableChoices, c)
		}
	}

	if len(availableChoices) == 0 {
		empty = true
		return
	}

	for i, e := range availableChoices {
		fmt.Printf("(%d) %s: %s\n", i+1, e.Name, e.Description)
	}

	var i int
	for {
		if _, err := fmt.Scan(&i); err == nil {
			if i >= 1 && i <= len(availableChoices) && availableChoices[i-1].Available(r.Game) {
				choice = availableChoices[i-1]
				return
			}
		}
	}
}

func (r *Runner) EnactChoice(choice Choice) {
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
}
