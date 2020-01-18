package storage

import "github.com/ulfurinn/talltale/internal/runner"

type Location struct {
	Name        string      `yaml:"name"`
	Description string      `yaml:"description"`
	Encounters  []Encounter `yaml:"encounters"`
}

func (l Location) Parse(id string) (location runner.Location) {
	location.ID = id
	location.Name = l.Name
	location.Description = l.Description
	for _, e := range l.Encounters {
		location.Encounters = append(location.Encounters, e.Parse())
	}
	return
}
