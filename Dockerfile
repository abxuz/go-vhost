# Build frontend
FROM node:lts-alpine AS frontend-build-stage
RUN corepack enable && corepack prepare yarn@stable --activate
WORKDIR /build
COPY ./go-vhost-frontend/ .
RUN yarn install && yarn build

# Build the backend binary
FROM golang:alpine AS backend-build-stage
ARG TARGETOS
ARG TARGETARCH
WORKDIR /build
COPY ./go-vhostd/ .
COPY --from=frontend-build-stage /build/build/ ./assets/html/
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build -ldflags "-s -w" -trimpath -o go-vhostd

# Deploy the application binary into a lean image
FROM alpine:latest AS release-stage
COPY --from=backend-build-stage /build/go-vhostd /usr/bin/
WORKDIR /data
ENTRYPOINT [ "go-vhostd" ]
CMD [ "--init" ]