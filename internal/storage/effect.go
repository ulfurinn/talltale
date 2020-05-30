package storage

type Effect struct {
	Trials []Trial         `yaml:"trials" json:"trials"`
	Pass   PlayerChangeSet `yaml:"pass" json:"pass"`
	Fail   PlayerChangeSet `yaml:"fail" json:"fail"`
}
