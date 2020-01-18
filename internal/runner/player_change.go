package runner

type PlayerChange func(*Player)

func AggregatePlayerChange(funcs []PlayerChange) PlayerChange {
	return func(p *Player) {
		for _, f := range funcs {
			f(p)
		}
	}
}
