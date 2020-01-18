package talltale

import (
	"errors"

	"bitbucket.org/ulfurinn/cli"
)

func Main(ctx *cli.Context) (err error) {
	world := ctx.String("world")
	if world == "" {
		return errors.New("--world must be provided")
	}
	var game Game
	game.ID = world
	stored, err := LoadWorld("worlds/" + world + "/world.yml")

	if err != nil {
		return
	}

	game.World = stored.Parse()
	game.Reset()

	runner := HttpRunner{
		Game: game,
		Port: ctx.Int("port"),
	}
	return runner.Run()
}
