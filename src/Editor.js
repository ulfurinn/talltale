import React, { Component } from "react";
import { Admin } from "react-admin";
import jsonServerProvider from "ra-data-json-server";

const dataProvider = jsonServerProvider("/editor");

class Editor extends Component {
    render() {
        return (<Admin dataProvider={dataProvider} />);
    }
}
export default Editor;
