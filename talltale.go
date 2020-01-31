package talltale

import (
	"bitbucket.org/ulfurinn/cli"
	"github.com/ulfurinn/talltale/internal/storage"
)

func Main(ctx *cli.Context) (err error) {
	if err = storage.Load(); err != nil {
		return
	}

	runner := HttpRunner{
		Port:        ctx.Int("port"),
		AllowEditor: ctx.Bool("allow-editor"),
	}
	return runner.Run()
}
