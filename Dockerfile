FROM golang:1.15-alpine AS server
WORKDIR /build
COPY go.mod go.sum *.go /build/
COPY cmd /build/cmd
COPY internal /build/internal
RUN go build -ldflags="-w -s" github.com/ulfurinn/talltale/cmd/talltale

FROM node:alpine AS react
WORKDIR /build
COPY config /build/config
COPY public /build/public
COPY scripts /build/scripts
COPY src /build/src
COPY package* /build/
RUN npm install && npm run build

FROM alpine
WORKDIR /talltale
COPY --from=server /build/talltale ./
COPY --from=react /build/build ./build
COPY worlds ./worlds
RUN ls -l
EXPOSE 8080
CMD ["./talltale", "--allow-editor"]
