import React from "react";
import ReactDOM from "react-dom";
import "./index.css";

function getScene(fn) {
    fetch("/scene", { credentials: "same-origin", cache: "no-cache" })
        .then(response => {
            return response.json();
        })
        .then(
            json => {
                console.log(json);
                fn(json);
            },
            error => {
                console.log(error);
            }
        );
}

function action(arg, fn) {
    fetch("/action", { method: 'POST', body: JSON.stringify(arg), headers: {
      'Content-Type': 'application/json'}, credentials: "same-origin", cache: "no-cache" })
        .then(response => {
            return response.json();
        })
        .then(
            json => {
                fn(json);
            },
            error => {
                console.log(error);
            }
        );
}

class Choice extends React.Component {
    render() {
        const classes = ["choice", (this.props.available ? "choice-available": "choice-unavailable")]
        return (
            <div className={classes.join(' ')} onClick={this.props.available ? this.props.onChoose : null}>
                <div className="choice-name">{this.props.name}</div>
                <div className="choice-description">
                    {this.props.description}
                </div>
            </div>
        );
    }
}

class Encounter extends React.Component {
    render() {
        const classes = ["encounter", (this.props.available ? "encounter-available": "encounter-unavailable")]
        return (
            <div className={classes.join(' ')} onClick={this.props.available ? this.props.onChoose : null}>
                <div className="encounter-name">{this.props.name}</div>
                <div className="encounter-description">
                    {this.props.description}
                </div>
            </div>
        );
    }
}

class Scene extends React.Component {
    setting() {
        return (<div className="scene-setting">
                    <div className="scene-name">{this.props.scene.name}</div>
                    <div className="scene-description">
                        {this.props.scene.story || this.props.scene.description}
                    </div>
                </div>);
    }

    render() {
        const choices = this.props.choices.map(action => (
            <Choice
                key={action.id}
                name={action.name}
                description={action.description}
                available={action.available}
                onChoose={() => this.props.onChooseAction(action.id)}
            />
        ));
        const encounters = this.props.encounters.map(encounter => (
            <Encounter
                key={encounter.id}
                name={encounter.name}
                description={encounter.description}
                available={encounter.available}
                onChoose={() => this.props.onChooseEncounter(encounter.id)}
            />
        ));
        const locations = [];
        return (
            <div className="scene">
                { this.setting() }
                { choices.length > 0 ? <div className="scene-choices">{choices}</div> : null }
                {locations.length > 0 ? <div className="scene-locations">{locations}</div> : null }
                { encounters.length > 0 ? <div className="scene-encounters">{encounters}</div> : null }
            </div>
        );
    }
}

class Game extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            world: {
                title: null,
            },
            scene: null,
            location: null,
            encounter: null,
            inventory: {},
            encounters: [],
            locations: [],
            choices: [],
            _loaded: false
        };

        this.chooseEncounter = this.chooseEncounter.bind(this);
        this.chooseLocation = this.chooseLocation.bind(this);
        this.chooseAction = this.chooseAction.bind(this);
    }
    componentDidMount() {
        getScene(game => {
            console.log("new state", game)
            this.setState(Object.assign({_loaded: true}, game));
        });
    }

    chooseEncounter(id) {
        console.log("choosing encounter "+id)
        action({choiceType: "encounter", choiceID: id}, game => {
            console.log("new state", game)
            this.setState(game);
        })
    }

    chooseLocation(id) {
        console.log("choosing location "+id)
        action({choiceType: "location", choiceID: id}, game => {
            console.log("new state", game)
            this.setState(game);
        })
    }

    chooseAction(id) {
        console.log("choosing action "+id)
        action({choiceType: "action", choiceID: id}, game => {
            console.log("new state", game)
            this.setState(game);
        })
    }

    render() {
        console.log("rendering state", this.state)
        return (
            <div className="game">
                <div className="world">
                    <div className="world-title">{this.state.world.title}</div>
                </div>
                { this.state._loaded ? <Scene
                    scene={this.state.scene}
                    locations={this.state.locations}
                    encounters={this.state.encounters}
                    choices={this.state.choices}
                    onChooseEncounter={this.chooseEncounter}
                    onChooseLocation={this.chooseLocation}
                    onChooseAction={this.chooseAction}
                /> : null }
            </div>
        );
    }
}

ReactDOM.render(<Game />, document.getElementById("root"));
