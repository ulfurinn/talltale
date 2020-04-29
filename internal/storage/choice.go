package storage

import "github.com/ulfurinn/talltale/internal/runner"

type Choice struct {
	ID          string               `yaml:"id" json:"id"`
	Name        string               `yaml:"name" json:"name"`
	Description string               `yaml:"description" json:"description"`
	Story       string               `yaml:"story" json:"story"`
	Conditions  map[string]Condition `yaml:"conditions" json:"conditions"`
	Effects     []Effect             `yaml:"effects" json:"effects"`
}

func (c *Choice) Parse() (choice runner.Choice, err error) {
	choice.ID = c.ID
	choice.Name = c.Name
	choice.Description = c.Description
	choice.Story = c.Story
	for _, cond := range c.Conditions {
		if parsed, err := cond.Parse(); err == nil {
			choice.Conditions = append(choice.Conditions, parsed)
		} else {
			return runner.Choice{}, err
		}
	}
	for _, effect := range c.Effects {
		choice.Effects = append(choice.Effects, effect.Parse())
	}
	return
}

func (c *Choice) normalise() {
	if c.Conditions == nil {
		c.Conditions = map[string]Condition{}
	}
	if c.Effects == nil {
		c.Effects = []Effect{}
	}
}
