package storage

import "github.com/ulfurinn/talltale/internal/runner"

type Choice struct {
	ID          string               `yaml:"id"`
	Name        string               `yaml:"name"`
	Description string               `yaml:"description"`
	Story       string               `yaml:"story"`
	Conditions  map[string]Condition `yaml:"conditions"`
	Effects     []Effect             `yaml:"effects"`
}

func (c Choice) Parse() (choice runner.Choice) {
	choice.ID = c.ID
	choice.Name = c.Name
	choice.Description = c.Description
	choice.Story = c.Story
	for _, cond := range c.Conditions {
		choice.Conditions = append(choice.Conditions, cond.Parse())
	}
	for _, effect := range c.Effects {
		choice.Effects = append(choice.Effects, effect.Parse())
	}
	return
}
