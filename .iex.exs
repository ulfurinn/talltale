import_file("~/.iex.exs")

alias TallTale.Repo
alias TallTale.Store.Game
import_if_available(Ecto.Query, only: [from: 2])
