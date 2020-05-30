package storage

type Location struct {
	ID          string      `yaml:"-" json:"id"`
	Name        string      `yaml:"name" json:"name"`
	Description string      `yaml:"description" json:"description"`
	Encounters  []Encounter `yaml:"encounters" json:"encounters"`
}

func (l *Location) normalise() {
	if l.Encounters == nil {
		l.Encounters = []Encounter{}
	}
	for i := range l.Encounters {
		l.Encounters[i].normalise()
	}
}
