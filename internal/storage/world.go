package storage

type World struct {
	ID     string `json:"id"`
	Global struct {
		Title string `yaml:"title" json:"title"`
	} `yaml:"global" json:"global"`
	Locations  map[string]Location `yaml:"locations" json:"locations"`
	PlayerSeed struct {
		Stats    map[string]int `yaml:"stats" json:"stats"`
		Location string         `yaml:"location" json:"location"`
	} `yaml:"player_seed" json:"player_seed"`
}
