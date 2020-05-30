package storage

type Encounter struct {
	ID          string               `yaml:"id" json:"id"`
	Name        string               `yaml:"name" json:"name"`
	Description string               `yaml:"description" json:"description"`
	Story       string               `yaml:"story" json:"story"`
	Conditions  map[string]Condition `yaml:"conditions" json:"conditions"`
	Choices     []Choice             `yaml:"choices" json:"choices"`
}

func (e *Encounter) normalise() {
	if e.Conditions == nil {
		e.Conditions = map[string]Condition{}
	}
	if e.Choices == nil {
		e.Choices = []Choice{}
	}

	for i, condition := range e.Conditions {
		e.Conditions[i] = condition
	}
	for i := range e.Choices {
		e.Choices[i].normalise()
	}
}
