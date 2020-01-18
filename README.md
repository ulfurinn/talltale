# talltale

An interactive fiction engine.

## Local dev session

[modd](https://github.com/cortesi/modd) is used to recompile and restart the Go server on code changes.

Start backend:

```
modd
```

Start frontend:

```
npm start
```

## Docker build

Consider cleaning up node_modules to avoid uploading all of that noise to the Docker daemon.

```
docker build -t talltale .
docker run -p 8080:8080 talltale
```
