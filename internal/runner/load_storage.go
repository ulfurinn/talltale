package runner

import (
	"errors"

	"github.com/ulfurinn/talltale/internal/storage"
)

func LoadWorld(stored storage.World) (world World, err error) {
	world.Title = stored.Global.Title
	world.Locations = make(map[string]Location)
	for i := range stored.Locations {
		var loc Location
		if loc, err = LoadLocation(stored.Locations[i]); err == nil {
			world.Locations[i] = loc
		} else {
			return
		}
	}

	world.TabulaRasa.Location = stored.PlayerSeed.Location
	world.TabulaRasa.Inventory = stored.PlayerSeed.Stats

	return
}

func LoadLocation(stored storage.Location) (location Location, err error) {
	location.ID = stored.ID
	location.Name = stored.Name
	location.Description = stored.Description
	location.Encounters = make([]Encounter, 0, len(stored.Encounters))
	for _, storedEnc := range stored.Encounters {
		var enc Encounter
		if enc, err = LoadEncounter(storedEnc); err == nil {
			location.Encounters = append(location.Encounters, enc)
		} else {
			return
		}
	}
	return
}

func LoadEncounter(stored storage.Encounter) (encounter Encounter, err error) {
	encounter.ID = stored.ID
	encounter.Name = stored.Name
	encounter.Description = stored.Description
	encounter.Story = stored.Story
	encounter.Conditions = make([]Condition, 0, len(stored.Conditions))
	for _, storedCond := range stored.Conditions {
		var cond Condition
		if cond, err = LoadCondition(storedCond); err == nil {
			encounter.Conditions = append(encounter.Conditions, cond)
		} else {
			return
		}
	}
	encounter.Choices = make([]Choice, 0, len(stored.Choices))
	for _, storedChoice := range stored.Choices {
		var choice Choice
		if choice, err = LoadChoice(storedChoice); err == nil {
			encounter.Choices = append(encounter.Choices, choice)
		} else {
			return
		}
	}
	return
}

func LoadChoice(stored storage.Choice) (choice Choice, err error) {
	choice.ID = stored.ID
	choice.Name = stored.Name
	choice.Description = stored.Description
	choice.Story = stored.Story
	for i := range stored.Conditions {
		var cond Condition
		if cond, err = LoadCondition(stored.Conditions[i]); err == nil {
			choice.Conditions = append(choice.Conditions, cond)
		} else {
			return
		}
	}
	for i := range stored.Effects {
		var effect Effect
		if effect, err = LoadEffect(stored.Effects[i]); err == nil {
			choice.Effects = append(choice.Effects, effect)
		} else {
			return
		}
	}
	return

}

func LoadEffect(stored storage.Effect) (effect Effect, err error) {
	for i := range stored.Trials {
		var trial Trial
		if trial, err = LoadTrial(stored.Trials[i]); err == nil {
			effect.Trials = append(effect.Trials, trial)
		} else {
			return
		}
	}
	if effect.Pass, err = LoadPlayerChangeSet(stored.Pass); err != nil {
		return
	}
	if effect.Fail, err = LoadPlayerChangeSet(stored.Fail); err != nil {
		return
	}
	return
}

func LoadCondition(stored storage.Condition) (condition Condition, err error) {
	switch {
	case stored.StatCondition != nil:
		return LoadStatConditionSet(stored.StatCondition)

	default:
		return nil, errors.New("no conditions defined")
	}
}

func LoadStatConditionSet(stored storage.StatConditionSet) (AggregateCondition, error) {
	sub := make([]Condition, 0, len(stored))
	for stat, c := range stored {
		c.Stat = stat
		if c, err := LoadStatCondition(c); err == nil {
			sub = append(sub, c)
		} else {
			return AggregateCondition{}, err
		}
	}
	return AggregateCondition{
		Conditions: sub,
	}, nil
}

func LoadStatCondition(stored storage.StatCondition) (StatCondition, error) {
	return StatCondition{
		Stat:            stored.Stat,
		Min:             stored.Min,
		Max:             stored.Max,
		HideUnavailable: stored.Hide,
	}, nil
}

func LoadPlayerChangeSet(pcs storage.PlayerChangeSet) (playerChange PlayerChange, err error) {
	funcs := []PlayerChange{}
	for _, c := range pcs {
		if f := LoadPlayerChange(c); f != nil {
			funcs = append(funcs, f)
		}
	}
	return AggregatePlayerChange(funcs), nil
}

func LoadPlayerChange(pc storage.PlayerChange) (playerChange PlayerChange) {
	switch {
	case pc.StatChange != nil:
		return LoadStatChange(*pc.StatChange)
	case pc.Redirect != nil:
		return LoadRedirect(*pc.Redirect)
	default:
		return nil
	}
}

func LoadStatChange(sc storage.StatChange) PlayerChange {
	return func(player *Player) {
		currentValue := player.Inventory[sc.Stat]
		var newValue int
		if sc.Absolute {
			newValue = sc.Change
		} else {
			newValue = currentValue + sc.Change
			if sc.NoMoreThan != nil && newValue > *sc.NoMoreThan {
				newValue = *sc.NoMoreThan
			}
			if sc.NoLessThan != nil && newValue < *sc.NoLessThan {
				newValue = *sc.NoLessThan
			}
		}
		player.Inventory[sc.Stat] = newValue
	}
}

func LoadRedirect(r storage.Redirect) PlayerChange {
	return func(player *Player) {
		player.Location = r.Location
	}
}

func LoadTrial(t storage.Trial) (trial Trial, err error) {
	switch {
	case t.Automatic:
		return AutomaticPass, nil

	default:
		return AutomaticFail, nil
	}
}
