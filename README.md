# Tall Tale

An interactive fiction engine.

Tall Tale is largely inspired by the storylet mechanism as seen in Failbetter Games' Fallen London/StoryNexus, but does not aim to be a full clone of the StoryNexus engine.

It comes with a small game world used to test and demo the engine features. It might or might not grow into a viable game on its own.

## Running the published version

```
docker pull ulfurinn/talltale:latest
docker run -p 8080:8080 ulfurinn/talltale:latest
```

Go to `http://localhost:8080` for the game runner and `http://localhost:8080/editor.html` for the game designer.

## Features

The project is its early stages and not fit for any serious authoring yet.

### Game runner

- [ ] persistent player sessions
- [ ] navigable world map
- [ ] equippables
- [ ] card decks (?)
- [ ] location styles
- [ ] encounter images
- [ ] stat images
- [ ] progression points (?)

### Game designer

- [ ] world-custom styles
- [ ] sub-stories

## Tech

Built with Go and React.

### Local dev session

[modd](https://github.com/cortesi/modd) is used to recompile and restart the Go server on code changes.
To install it, run `go get github.com/cortesi/modd` and make sure it is visible in your `PATH` (recent Go versions will put it under `$HOME/go/bin` by default). On OS X, you can also get it with `brew install modd`.

Once `modd` is installed, run these two in different terminal sessions:

```
rake dev:back
rake dev:front
```

### Local docker build

```
rake docker:build
rake docker:run
```
