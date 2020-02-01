import React, { Component } from "react";
import RestClient from "another-rest-client";
import itemSelector from "./shared";

const api = new RestClient("/editor");

api.res("worlds").res("locations");

function WorldPicker(props) {
    return (
        <div className="world-picker">
            Pick a world:
            <select onChange={itemSelector(props.worlds, props.onselect, true)}>
                <option key={null}>--- select world ---</option>
                {props.worlds.map(world => (
                    <option key={world.id}>{world.global.title}</option>
                ))}
            </select>
        </div>
    );
}

function LocationPicker(props) {
    var items = [];
    for (let id in props.locations) {
        items.push(Object.assign({ id: id }, props.locations[id]));
    }
    items.sort((a, b) => {
        if (a.name > b.name) return 1;
        if (a.name < b.name) return -1;
        return 0;
    });
    return (
        <div className="location-picker">
            <header>Locations:</header>
            {items.map(location => (
                <div
                    key={location.id}
                    className={[
                        "element",
                        props.location && props.location.id === location.id
                            ? "selected"
                            : "deselected"
                    ].join(" ")}
                    onClick={_ => props.onselect(location.id)}
                >
                    {location.name}
                </div>
            ))}
        </div>
    );
}

function EncounterListElement(props) {
    return (
        <div
            className={[
                "element",
                props.selected ? "selected" : "deselected"
            ].join(" ")}
            onClick={props.onselect}
        >
            <header>{props.encounter.name}</header>
            <section className="access-conditions">
                {Object.entries(props.encounter.conditions).map(
                    ([id, condition]) => (
                        <AccessCondition
                            key={id}
                            id={id}
                            condition={condition}
                        />
                    )
                )}
            </section>
        </div>
    );
}

function AccessConditionStat(props) {
    return (
        <div className="condition-stat">
            {props.stat}{" "}
            {props.rule.min !== null ? `at least ${props.rule.min}` : null}{" "}
            {props.rule.max !== null ? `no more than ${props.rule.max}` : null}
            <br />
            {props.rule.hide ? "Hide when locked" : "Display when locked"}
        </div>
    );
}

function AccessCondition(props) {
    return props.condition.stat
        ? Object.entries(props.condition.stat).map(([stat, rule]) => (
              <AccessConditionStat key={stat} stat={stat} rule={rule} />
          ))
        : null;
}

function Trial(props) {
    return (
        <div className="trial">
            {props.trial.automatic ? <div>automatic pass</div> : null}
        </div>
    );
}

function StatChange(props) {
    return (
        <div className="consequence stat-change">
            {[
                `Change ${props.stat_change.stat}`,
                `by ${props.stat_change.change}`,
                props.stat_change.no_more_than !== null
                    ? `up to ${props.stat_change.no_more_than}`
                    : null,
                props.stat_change.no_less_than !== null
                    ? `down to ${props.stat_change.no_less_than}`
                    : null
            ]
                .filter(e => !!e)
                .join(" ")}
        </div>
    );
}

function Redirect(props) {
    return (
        <div className="consequence redirect">
            Move to location {props.redirect.location}
        </div>
    );
}

function Consequence(props) {
    if (props.consequence.stat_change) {
        return <StatChange stat_change={props.consequence.stat_change} />;
    }
    if (props.consequence.redirect) {
        return <Redirect redirect={props.consequence.redirect} />;
    }
    return null;
}

function Consequences(props) {
    return (
        <div className="consequences">
            <div>On {props.title}:</div>
            {props.consequences.map((c, i) => (
                <Consequence key={`consequence-${i}`} consequence={c} />
            ))}
        </div>
    );
}

function Effect(props) {
    return (
        <div className="effect">
            <section className="trials">
                {props.effect.trials.map((trial, i) => (
                    <Trial key={`trial-${i}`} trial={trial} />
                ))}
            </section>
            <section className="pass">
                {props.effect.pass ? (
                    <Consequences
                        consequences={props.effect.pass}
                        title="pass"
                    />
                ) : null}
            </section>
            <section className="fail">
                {props.effect.fail ? (
                    <Consequences
                        consequences={props.effect.fail}
                        title="fail"
                    />
                ) : null}
            </section>
        </div>
    );
}

function Choice(props) {
    return (
        <div className="choice">
            <section className="properties">
                <header>id:{props.choice.id}</header>
                <section className="property">
                    Name: {props.choice.name}
                </section>
                <section className="property">
                    Description: {props.choice.description}
                </section>
                <section className="property">
                    Story: {props.choice.story}
                </section>
            </section>
            <section className="access-conditions">
                <header>Access conditions</header>
                {Object.entries(props.choice.conditions).map(
                    ([id, condition]) => (
                        <AccessCondition
                            key={id}
                            id={id}
                            condition={condition}
                        />
                    )
                )}
            </section>
            <section className="effects">
                <header>Effects</header>
                {props.choice.effects.map((effect, i) => (
                    <Effect key={`effect-${i}`} effect={effect} />
                ))}
            </section>
        </div>
    );
}

function EncounterEditor(props) {
    console.log("encounter", props);
    return (
        <div className="encounter">
            <section className="properties">
                <header className="title">
                    {props.encounter.name} (id:{props.encounter.id})
                </header>
                <section className="property">
                    Name: {props.encounter.name}
                </section>
                <section className="property">
                    Description: {props.encounter.description}
                </section>
                <section className="property">
                    Story: {props.encounter.story}
                </section>
            </section>
            <section className="choices">
                <header>Choices</header>
                {props.encounter.choices.map(choice => (
                    <Choice key={choice.id} choice={choice} />
                ))}
            </section>
        </div>
    );
}

function Location(props) {
    console.log("location", props);
    return (
        <div className="location">
            <section className="properties">
                <header className="title">
                    {props.location.name} (id:{props.location.id})
                </header>
            </section>
            <section className="split">
                <div className="child-list">
                    <div className="encounter-picker">
                        <div className="title">Encounters</div>
                        {props.location.encounters.map(e => (
                            <EncounterListElement
                                key={e.id}
                                encounter={e}
                                selected={
                                    props.encounter &&
                                    props.encounter.id === e.id
                                }
                                onselect={_ => props.onselectencounter(e.id)}
                            />
                        ))}
                    </div>
                </div>
                <div className="child-editor">
                    {props.encounter ? (
                        <EncounterEditor encounter={props.encounter} />
                    ) : null}
                </div>
            </section>
        </div>
    );
}

function World(props) {
    return (
        <div className="world">
            <header className="title">{props.world.global.title}</header>
            <section className="split">
                <section className="child-list">
                    <LocationPicker
                        locations={props.world.locations}
                        location={props.location}
                        onselect={props.onselectlocation}
                    />
                </section>
                <section className="child-editor">
                    {props.location ? (
                        <Location
                            location={props.location}
                            encounter={props.encounter}
                            onselectencounter={props.onselectencounter}
                        />
                    ) : null}
                </section>
            </section>
        </div>
    );
}

class Editor extends Component {
    constructor(props) {
        super(props);
        this.state = {
            _init: false,
            worlds: [],
            world: null,
            location: null,
            encounter: null
        };

        this.setWorld = this.setWorld.bind(this);
        this.setLocation = this.setLocation.bind(this);
        this.setEncounter = this.setEncounter.bind(this);
    }
    async componentDidMount() {
        let worlds = await api.worlds.get();
        this.setState({ _init: true, worlds: worlds });
    }
    async setWorld(id) {
        if (id) {
            let world = await api.worlds(id).get();
            this.setState({ world: world, location: null, encounter: null });
        } else {
            this.setState({ world: null, location: null, encounter: null });
        }
    }
    setLocation(id) {
        if (id) {
            this.setState(state => {
                return {
                    location: Object.assign(
                        { id: id },
                        state.world.locations[id]
                    ),
                    encounter: null
                };
            });
        } else {
            this.setState({ location: null, encounter: null });
        }
    }
    setEncounter(id) {
        if (id) {
            this.setState(state => {
                return {
                    encounter: Object.assign(
                        { id: id },
                        state.location.encounters.find(
                            encounter => encounter.id === id
                        )
                    )
                };
            });
        } else {
            this.setState({ location: null, encounter: null });
        }
    }
    render() {
        return (
            <div className="editor">
                <header className="editor-header">
                    TallTale Editor |{" "}
                    {this.state._init ? (
                        <WorldPicker
                            worlds={this.state.worlds}
                            onselect={this.setWorld}
                        />
                    ) : null}
                </header>
                {this.state.world ? (
                    <World
                        world={this.state.world}
                        location={this.state.location}
                        encounter={this.state.encounter}
                        onselectlocation={this.setLocation}
                        onselectencounter={this.setEncounter}
                    />
                ) : null}
            </div>
        );
    }
}
export default Editor;
