package talltale

import "fmt"

func Run(g *Game) {
	for {
		fmt.Println("========")
		Scenery(*g)

		enc, gameOver := PresentEncounters(*g)
		if gameOver {
			break
		}

		fmt.Printf(">> %s\n>> %s\n", enc.Name, enc.Story)

		choice, empty := PresentChoices(enc, *g)
		if empty {
			// must pick another encounter
			fmt.Println("There is nothing for you here. Try something else.")
			continue
		}
		fmt.Printf(">> %s\n>> %s\n", choice.Name, choice.Story)

		EnactChoice(choice, &g.Player)
	}
	fmt.Println("The End")
}

func Scenery(g Game) {
	l := g.Location()
	fmt.Println(l.Name)
	fmt.Println(l.Description)
}

func PresentEncounters(g Game) (encounter Encounter, gameOver bool) {
	var availableEncounters []Encounter

	l := g.Location()
	for _, e := range l.Encounters {
		if e.Displayable(g) {
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
			if i >= 1 && i <= len(availableEncounters) && availableEncounters[i-1].Available(g) {
				encounter = availableEncounters[i-1]
				return
			}
		}
	}
}

func PresentChoices(enc Encounter, g Game) (choice Choice, empty bool) {
	var availableChoices []Choice

	for _, c := range enc.Choices {
		if c.Displayable(g) {
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
			if i >= 1 && i <= len(availableChoices) && availableChoices[i-1].Available(g) {
				choice = availableChoices[i-1]
				return
			}
		}
	}
}

func EnactChoice(choice Choice, player *Player) {
	for _, e := range choice.Effects {
		if e.Success(player) {
			fmt.Println("You are successful.")
			if e.Pass != nil {
				e.Pass(player)
			}
		} else {
			fmt.Println("You failed.")
			if e.Fail != nil {
				e.Fail(player)
			}
		}
	}
}
