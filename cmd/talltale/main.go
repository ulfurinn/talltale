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
			cli.IntOption{
				Name:  "port",
				Value: 8080,
			},
		},
		Action: talltale.Main,
	}
	app.RunMain()
}
