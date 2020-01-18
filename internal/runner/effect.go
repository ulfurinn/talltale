package runner

type Effect struct {
	Trials []Trial
	Pass   PlayerChange
	Fail   PlayerChange
}

func (e Effect) Success(player Player) bool {
	for _, trial := range e.Trials {
		if !trial(player) {
			return false
		}
	}
	return true
}
