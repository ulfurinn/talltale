package storage

type PlayerChangeSet []PlayerChange

type PlayerChange struct {
	StatChange *StatChange `yaml:"stat_change,omitempty" json:"stat_change,omitempty"`
	Redirect   *Redirect   `yaml:"redirect,omitempty" json:"redirect,omitempty"`
}

type StatChange struct {
	Stat       string `yaml:"stat" json:"stat"`
	Change     int    `yaml:"change" json:"change"`
	NoLessThan *int   `yaml:"no_less_than" json:"no_less_than"`
	NoMoreThan *int   `yaml:"no_more_than" json:"no_more_than"`
	Absolute   bool   `yaml:"absolute" json:"absolute"`
}

type Redirect struct {
	Location string `yaml:"location" json:"location"`
}
