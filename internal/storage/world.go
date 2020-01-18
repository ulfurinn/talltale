package storage

type World struct {
	Global struct {
		Title string `yaml:"title"`
	} `yaml:"global"`
	Locations  map[string]Location `yaml:"locations"`
	PlayerSeed struct {
		Stats    map[string]int `yaml:"stats"`
		Location string         `yaml:"location"`
	} `yaml:"player_seed"`
}
