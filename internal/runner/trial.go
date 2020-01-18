package runner

type Trial func(Player) bool

var AutomaticPass Trial = func(Player) bool { return true }
var AutomaticFail Trial = func(Player) bool { return false }
