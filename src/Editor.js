import React, { Component } from "react";
import RestClient from 'another-rest-client';
const api = new RestClient('/editor');

api.res('worlds').res('locations');

function itemSelector(items, fn, withHeader) {
    return e => {
        let index = e.target.selectedIndex;
        var id = null;
        if(index > (withHeader ? 0 : -1)) {
            id = items[index - (withHeader ? 1 : 0)].id;
        }
        fn(id);
    };
}

function WorldPicker(props) {
    return (
        <div className="world-picker">
        Pick a world: <select onChange={itemSelector(props.worlds, props.onselect, true)}>
        <option key={null}>--- select world ---</option>
        { props.worlds.map(world => <option key={world.id}>{world.global.title}</option>) }
        </select>
        </div>
    );
}

function LocationPicker(props) {
    var items = [];
    for(let id in props.locations) {
        items.push(Object.assign({id: id}, props.locations[id]));
    }
    items.sort((a, b) => {
        if(a.name > b.name) return 1;
        if(a.name < b.name) return -1;
        return 0;
    })
    return (<div>
        Pick a location: <select onChange={itemSelector(items, props.onselect, false)}>
        { items.map(location => <option key={location.id}>{location.name}</option>) }
        </select>
    </div>);
}

function Location(props) {
    console.log("location", props)
    return (
        <div className="location">
            Location: {props.location.name}
        </div>
    );
}

function World(props) {
    return (
        <div className="world">
            <div className="title">{props.world.global.title}</div>
            <LocationPicker locations={props.world.locations} onselect={props.onselectlocation} />
            { props.location ? <Location location={props.location} /> : null }
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
        };

        this.setWorld = this.setWorld.bind(this);
        this.setLocation = this.setLocation.bind(this);
    }
    async componentDidMount() {
        let worlds = await api.worlds.get();
        this.setState({_init: true, worlds: worlds});
    }
    async setWorld(id) {
        if(id) {
            let world = await api.worlds(id).get();
            this.setState({world: world, location: null});
        } else {
            this.setState({world: null, location: null});
        }
    }
    setLocation(id) {
        if(id) {
        this.setState(state => {
            return {location: Object.assign({id: id}, state.world.locations[id])};
        });
    } else {
        this.setState({location: null});
    }
    }
    render() {
        return (
            <div className="editor">
            <div className="header">
            { this.state._init ? <WorldPicker worlds={this.state.worlds} onselect={this.setWorld} /> : null }
            </div>
            { this.state.world ? <World world={this.state.world} location={this.state.location} onselectlocation={this.setLocation} /> : null }
            </div>
        );
    }
}
export default Editor;
