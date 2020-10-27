# Tall Tale

An interactive fiction engine.

Tall Tale is largely inspired by the storylet mechanism as seen in Failbetter Games' Fallen London/StoryNexus, but does not aim to be a full clone of the StoryNexus engine.

It comes with a small game world used to test and demo the engine features. It might or might not grow into a viable game on its own.

The project is its very early stages and not fit for any public use yet, as evidenced by the features list being very empty.

## Running the published version

```
docker pull ulfurinn/talltale:latest
docker run -p 8080:8080 ulfurinn/talltale:latest
```

Go to `http://localhost:8080` for the game runner and `http://localhost:8080/editor.html` for the game designer.

## Features

### Game runner

- [ ] persistent player sessions
- [ ] navigable world map
- [ ] equippables
- [ ] card decks (?)
- [ ] location styles
- [ ] encounter images
- [ ] stat images
- [ ] progress points (?)
- [ ] progress curves (?)
- [ ] multiple worlds per player session (?)

### Game designer

- [ ] modifying the content
- [ ] persisting the changes
- [ ] world-custom styles
- [ ] sub-stories

## Tech

Built with Go and React.

### Local dev session

Run `npm install` on a fresh checkout.

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
