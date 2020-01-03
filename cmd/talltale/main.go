package main

import (
	"fmt"
	"os"

	"github.com/ulfurinn/talltale"
)

func main() {
	stored, err := talltale.LoadWorld("world.yml")
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	var game talltale.Game
	game.World, game.Player = stored.Parse()
	talltale.Run(&game)
}
