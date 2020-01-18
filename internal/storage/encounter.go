package storage

import "github.com/ulfurinn/talltale/internal/runner"

type Encounter struct {
	ID          string               `yaml:"id"`
	Name        string               `yaml:"name"`
	Description string               `yaml:"description"`
	Story       string               `yaml:"story"`
	Conditions  map[string]Condition `yaml:"conditions"`
	Choices     []Choice             `yaml:"choices"`
}

func (e Encounter) Parse() (encounter runner.Encounter) {
	encounter.ID = e.ID
	encounter.Name = e.Name
	encounter.Description = e.Description
	encounter.Story = e.Story
	for _, cond := range e.Conditions {
		encounter.Conditions = append(encounter.Conditions, cond.Parse())
	}
	for _, choice := range e.Choices {
		encounter.Choices = append(encounter.Choices, choice.Parse())
	}
	return
}
