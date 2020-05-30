package storage

type Choice struct {
	ID          string               `yaml:"id" json:"id"`
	Name        string               `yaml:"name" json:"name"`
	Description string               `yaml:"description" json:"description"`
	Story       string               `yaml:"story" json:"story"`
	Conditions  map[string]Condition `yaml:"conditions" json:"conditions"`
	Effects     []Effect             `yaml:"effects" json:"effects"`
}

func (c *Choice) normalise() {
	if c.Conditions == nil {
		c.Conditions = map[string]Condition{}
	}
	if c.Effects == nil {
		c.Effects = []Effect{}
	}
}
