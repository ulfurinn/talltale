package storage

import "github.com/ulfurinn/talltale/internal/runner"

type Encounter struct {
	ID          string               `yaml:"id" json:"id"`
	Name        string               `yaml:"name" json:"name"`
	Description string               `yaml:"description" json:"description"`
	Story       string               `yaml:"story" json:"story"`
	Conditions  map[string]Condition `yaml:"conditions" json:"conditions"`
	Choices     []Choice             `yaml:"choices" json:"choices"`
}

func (e *Encounter) Parse() (encounter runner.Encounter, err error) {
	encounter.ID = e.ID
	encounter.Name = e.Name
	encounter.Description = e.Description
	encounter.Story = e.Story
	encounter.Conditions = make([]runner.Condition, 0, len(e.Conditions))
	for _, cond := range e.Conditions {
		if c, err := cond.Parse(); err == nil {
			encounter.Conditions = append(encounter.Conditions, c)
		} else {
			return runner.Encounter{}, err
		}
	}
	encounter.Choices = make([]runner.Choice, 0, len(e.Choices))
	for _, choice := range e.Choices {
		if parsed, err := choice.Parse(); err == nil {
			encounter.Choices = append(encounter.Choices, parsed)
		} else {
			return runner.Encounter{}, err
		}
	}
	return
}

func (e *Encounter) normalise() {
	if e.Conditions == nil {
		e.Conditions = map[string]Condition{}
	}
	if e.Choices == nil {
		e.Choices = []Choice{}
	}

	for i, condition := range e.Conditions {
		condition.normalise()
		e.Conditions[i] = condition
	}
	for i := range e.Choices {
		e.Choices[i].normalise()
	}
}
