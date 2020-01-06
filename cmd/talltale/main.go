package main

import (
	"bitbucket.org/ulfurinn/cli"
	"github.com/ulfurinn/talltale"
)

func main() {
	app := cli.NewApp()
	app.Main = cli.Command{
		Options: []cli.Option{
			cli.StringOption{
				Name: "world",
			},
		},
		Action: talltale.Main,
	}
	app.RunMain()
}
