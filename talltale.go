package talltale

import (
	"errors"

	"bitbucket.org/ulfurinn/cli"
	"github.com/ulfurinn/talltale/internal/runner"
	"github.com/ulfurinn/talltale/internal/storage"
)

func Main(ctx *cli.Context) (err error) {
	world := ctx.String("world")
	if world == "" {
		return errors.New("--world must be provided")
	}
	stored, err := storage.LoadWorld(world)

	if err != nil {
		return
	}

	game := &runner.Game{}
	game.World = stored.Parse()
	game.Reset()

	runner := HttpRunner{
		Game:        game,
		Port:        ctx.Int("port"),
		AllowEditor: ctx.Bool("allow-editor"),
	}
	return runner.Run()
}
