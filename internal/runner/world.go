package runner

type World struct {
	Title      string
	Locations  map[string]Location
	TabulaRasa struct {
		Location  string
		Inventory map[string]int
	}
}
